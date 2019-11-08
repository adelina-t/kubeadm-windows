mkdir -force "C:\Program Files\windows-node"
$env:Path += ";C:\Program Files\windows-node"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

$kubeletBinPath = "C:\Program Files\windows-node\kubelet.exe"

# use forked kubelet until https://github.com/kubernetes/kubernetes/pull/84649 is merged / released
curl.exe -Lo $kubeletBinPath https://storage.googleapis.com/pks-windows-misc/kubelet.exe
curl.exe -Lo "C:\Program Files\windows-node\kubeadm.exe" https://dl.k8s.io/v1.16.2/bin/windows/amd64/kubeadm.exe
curl.exe -Lo "C:\Program Files\windows-node\wins.exe" https://github.com/rancher/wins/releases/download/v0.0.4/wins.exe

# Install and configure Docker and create host network
docker network create -d nat host

stop-service rancher-wins
wins.exe srv app run --register
start-service rancher-wins

mkdir -force /var/log/kubelet
New-Service -Name "kubelet" -StartupType Automatic -DependsOn "docker" -BinaryPathName "$kubeletBinPath --windows-service --cert-dir=$env:SYSTEMDRIVE\var\lib\kubelet\pki --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --hostname-override=$(hostname) --pod-infra-container-image=`"mcr.microsoft.com/k8s/core/pause:1.2.0`" --enable-debugging-handlers  --cgroups-per-qos=false --enforce-node-allocatable=`"`" --network-plugin=cni --resolv-conf=`"`" --log-dir=/var/log/kubelet --logtostderr=false"

New-NetFirewallRule -Name kubelet -DisplayName 'kubelet' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 10250
