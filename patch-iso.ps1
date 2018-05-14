
Function Patch-ISO{
Param(
$ISOFile = 'C:\packer\iso\en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso',
$patch_dir = '.\patches\2012R2',
$dism_dir = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM',
$oscdimg_dir = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg'
)
$ISOMediaFolder = (New-item -Path ".\$(New-guid)" -ItemType Directory).FullName
$wim_path = "$ISOMediaFolder\sources\install.wim"

$driveLetter = (Mount-DiskImage -ImagePath $ISOFile -StorageType ISO -PassThru | Get-Volume).driveletter
Copy-item -Path "$driveLetter`:\*" -Destination "$ISOMediaFolder\" -Recurse -Container -Force
Set-ItemProperty -Path $wim_path -Name IsReadOnly -Value $false -Force
Dismount-DiskImage -ImagePath $ISOFile -StorageType ISO -Verbose
$images = Get-WindowsImage -ImagePath $wim_path
$images_count = $images.Count
[int]$image_index = 0
ForEach($image in $images)
{
$image_index += 1;$image_percent = ($image_index / $images_count) * 100
Write-progress -Activity "Image" -Status $($image.ImageName) -Id 1 -PercentComplete $image_percent -Verbose
$imageIndex = $image.imageIndex
$MountDir = (New-item -Path ".\$(New-guid)" -ItemType Directory).FullName
Mount-WindowsImage -ImagePath $wim_path -Path $MountDir -Index $imageIndex -Verbose
$updates = Get-ChildItem -Path $patch_dir
[int]$updates_count = Get-ChildItem -Path $patch_dir | Measure-Object | %{$_.count}
[int]$updates_index = 0
ForEach($update in  $updates)
{
$updates_index += 1;$updates_percent = ($updates_index / $updates_count) * 100
Write-Progress -Activity "Patching Image" -Status $($update.FullName) -PercentComplete $updates_percent -Id 2 -ParentId 1
Try{
    Add-WindowsPackage -PackagePath $($update.fullname) -Path $mountdir -NoRestart
    Write-Output "$($image.ImageName) >>> Patch: $($update.fullname) Applied  $updates_index of $updates_count ($updates_percent)"}
Catch{
    Write-Output "ERROR Applying $($image.ImageName) >>> Patch:$($update.fullname)" 
    }
}
Dismount-WindowsImage -Path $MountDir -Save -Verbose
Remove-Item -Path $MountDir -Force -Recurse | out-null

}
$BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$ISOMediaFolder\boot\etfsboot.com","$ISOMediaFolder\efi\Microsoft\boot\efisys_noprompt.bin"
$ISOFilenew = "NEW_$ISOFile"
Start-Process -FilePath "$oscdimg_dir\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"$ISOMediaFolder","$ISOFilenew") -PassThru -Wait -NoNewWindow
}






