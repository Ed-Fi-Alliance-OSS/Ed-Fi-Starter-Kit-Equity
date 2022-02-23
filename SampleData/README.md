# Ed-Fi-Starter-Kit-Equity

## The Power BI scripts are for GrandBend Database ODS v5.3
The scripts for inserting the sample data for the PowerBI file using the ODS 5.3 (GrandBend) version are in the PowerBI folder.

To insert the sample data, you can run Add-SampleData.ps1 in PowerShell or you can run each of the DB scripts individually.

## The scripts are for Glendale Database v3.2

### Steps to load the Glendale Data

1. Download the database from [here](https://odsassets.blob.core.windows.net/public/Glendale/EdFi_Ods_Glendale_v32_20200224.7z).
2. Restore database from the downloaded file, the name of the database should be EdFi_Ods_Glendale_v32.
3. Download [this zip file](https://odsassets.blob.core.windows.net/public/starter-kits/Equity/Data.zip) containing the data insert scripts.
4. Uncompress the file.
5. Run the sql scripts in order from 0_data.sql to 2_data.sql on the EdFi_Ods_Glendale_v32 database.
