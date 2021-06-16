# Ed-Fi-Starter-Kit-Equity

## Steps to build Equity Starter Kit Automated Machine Image

This README outlines the steps for creating a virtual hard disk image containing
an evaluation copy of Windows 2019 Server, with SQL Server 2019 Express edition,
SQL Server Management Studio, Google Chrome, Dot Net Framework 4.8, the Dot Net
Core SDK, and NuGet Package Manager.

## Quick Start

If you want to jump ahead, there are three steps

- Install the prerequisites: Hyper-V and Packer
- Clone the Ed-Fi-Starter-Kit-Equity repository from Ed-Fi-Alliance-OSS on
  Github
- Run the build.ps1 as an Admin user

## Step by step

### Clone the repo

Clone the [Starter Kit Equity repository](https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Starter-Kit-Equity/)

### Turn on Windows features for Hyper-V

  You will need both sub-items: Hyper-V Platform and Hyper-V Management Tools.
  For directions on enabling these features, follow the directions found
  [here](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v#enable-the-hyper-v-role-through-settings)

### Download an install Packer

```powershell
choco install Packer
```

### Open a PowerShell console (greater or equal to PSVersion 5) in elevated mode

Set your location in the console to the Ed-Fi-Starter-Kit-Equity root folder.
Execute the build.ps1 to create your AMI.

## Optional Parameters
There are two optional parameters that you can pass to the build script for
specific scenarios. The first is if you have a Hyper-V VM Switch defined in
Hyper-V already you can add `-vmSwitch` along with the name of your Switch.
If this parameter is not specified, then a Switch with the name
`packer-hyperv-iso` will be created. The second optional parameter is for if you
run the build and see the following error output

```
hyperv-iso: Download failed unexpected EOF
hyperv-iso: error downloading ISO: [unexpected EOF]
...
Build 'hyperv-iso' errored after 10 minutes 26 seconds: error downloading ISO: [unexpected EOF]
```

If you see this, then the build is having a problem downloading the Windows
Server 2019 iso file, so you should try to manually download the iso from [this
url](https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso),
move the iso file to an easily accessible location, and then use the `-isoUrl`
parameter in the build script to specifiy where the iso file is and the build
script will use that file instead of trying to download it.

Below are examples showing how to pass these two parameters to the build script.

```powershell
#default way to run build
PS> .\build.ps1

#build with vmSwitch parameter
PS> .\build.ps1 -vmSwitch existingVMSwitchName

#build with isoUrl parameter
PS> .\build.ps1 -isoUrl C:\projects\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso

#build with both vmSwitch and isoUrl parameter
PS> .\build.ps1 -vmSwitch existingVMSwitchName -isoUrl C:\projects\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso
```

> :exclamation: IMPORTANT: Disconnect from any VPNs. This will cause issues with Hypervisor
> connectivity.

> NOTE: The build takes upwards of three hours.

The build will download and install Windows Server 2019 Evaluation edition, with
a license that is valid for 180 days. NuGet Package Management is installed,
followed by Chocolatey for automated software package installs of the following
software: Dot Net Framework 4.8, Dot Net Core 3.1 SDK, SQL Server 2019 Express,
SQL Server Management Studio, Google Chrome, and any of their Chocolatey package
dependencies (Windows update packages for Dot Net).

Next, the build invokes the installation for the database, ODS Tech Suite, and Data
Import.

When complete, the virtual machine artifacts will be created in the
`output-hyperv-iso` folder.

## Build outcome

The `output-hyperv-iso` folder will contain Hyper-V hard disk images for the
asmt-starter-kit Virtual Machine image populated with the the latest databases
enhanced with Analytics Middle Tier; the ODS API Tech Suite with Admin App.

## Testing the image

You can then use Hyper-V Manager to import the virtual machine. Point the
directory to the output folder to install. The user and password is `vagrant`.

## Contributing

The Ed-Fi Alliance welcomes code contributions from the community. Please read
the [Ed-Fi Contribution
Guidelines](https://techdocs.ed-fi.org/display/ETKB/Code+Contribution+Guidelines)
for detailed information on how to contribute source code.

Looking for an easy way to get started? Search for tickets with label
"up-for-grabs" in [Tracker](https://tracker.ed-fi.org/issues/?filter=14107);
these are nice-to-have but low priority tickets that should not require in-depth
knowledge of the code base and architecture.

## Legal Information

Copyright (c) 2021 Ed-Fi Alliance, LLC.

_Not released under an open source license at this time._

See [NOTICES](NOTICES.md) for additional copyright and license notifications.

## ODS/API/Admin Installer

To install ODS/API/Admin you need to follow these steps:

1. Configure the database properties in the file configuration.json.

    ```json
    "databases": {
        "applicationCredentials": {
            "databaseUser" : "",
            "databasePassword" : "",
            "useIntegratedSecurity" : true
        },
        "installCredentials": {
            "databaseUser" : "",
            "databasePassword" : "",
            "useIntegratedSecurity" : true
        },
        "engine" : "SQLServer",
        "databaseServer" : "(local)",
        "databasePort" : "",
        "adminDatabaseName" : "EdFi_Admin",
        "odsDatabaseName" : "EdFi_Ods",
        "securityDatabaseName" : "EdFi_Security",
        "useTemplates" : false,
        "odsTemplate" : "populated",
        "noDuration" : false,
        "dropDatabases" : true,
        "databasePackageVersion" : "5.0.0",
        "apiMode": "sharedinstance",
        "odsTokens": []
    },
    ```

2. Make sure you have the Databases, Web Api and Admin App installation flags
   on.

    ```json
   "installDatabases": true,
   "installAdminApp": true,
   "installWebApi": true,
   "installPrerequisites": true,
    ```

3. Then, open a PowerShell console with Administrator privileges and execute
   install.ps1

    ```powershell
    .\install.ps1
    ```

### Known Errors

* If some prerequisites were installed is probably you will have to reboot and
  try again to run the powershell script.
* If the powershell console display an error about the .net framework 4.8 not
  installed you will have to reboot and try again to run the powershell script.

## Analytics Middle Tier Installer

To install Analytics Middle Tier you need to follow these steps:

1. Make sure you have the Analytics Middle Tier installation flag on. Open
   configuration.json and make sure the installAMT value is set to true.

    ```json
    "installAMT": true,
    ```

2. On the same file. Make sure the database configuration is correct. Identify
   in your configuration.json file the following values, and change them if
   needed. These are the ones used by Analytics Middle Tier installer.

    ```json
    "databases": {
        "applicationCredentials": {
            "databaseUser" : "",
            "databasePassword" : "",
            "useIntegratedSecurity" : true
        },
        "engine" : "SQLServer",
        "databaseServer" : "localhost",
        "databasePort" : "",
        "odsDatabaseName" : "",
    },
    ```

3. To update the version and the AMT options to be installed, the corresponding
   section can be modified.

    ```json
    "AMT": {
        "version": "2.2.0",
        "amtDownloadPath": "C:\\temp\\downloads",
        "amtInstallerPath": "C:\\temp\\tools",
        "options": "indexes rls qews ews chrab"
    }
    ```

4. Then, open a PowerShell console with Administrator privileges and execute
   install.ps1

    ```powershell
    .\install.ps1
    ```

5. To uninstall you must execute uninstall.ps1

    ```powershell
    .\uninstall.ps1
    ```
