# Script to collect RDP users
# Define the list of machines
$computers = @("MACHINE1", "MACHINE2", "MACHINE3", "MACHINE4", "MACHINE5", "MACHINE6")

# Define the output file path
$outputFile = "C:\Path\To\Output\RDP_users.txt"

# Initialize the output file
Set-Content -Path $outputFile -Value " " -Force

# Loop through each machine
foreach ($computer in $computers) {
    # Check if the machine is online
    if (Test-Connection -ComputerName $computer -Quiet) {
        try {
            # Get users connected via RDP
            $users = qwinsta /server:$computer

            # Write the machine name and users to the output file
            Add-Content -Path $outputFile -Value "Users logged in to $computer"
            $users | ForEach-Object { Add-Content -Path $outputFile -Value $_ }
        } catch {
            Add-Content -Path $outputFile -Value "Error retrieving users from $computer: $_"
        }
    } else {
        # Write a message to the output file if the machine is offline
        Add-Content -Path $outputFile -Value "$computer is offline."
    }
}

# Function to find users with multiple connections
function Find-MultipleUsers {
    param (
        [string]$file
    )

    $users = @{}

    # Read the input file
    Get-Content $file | ForEach-Object {
        $line = $_.Trim()
        
        if ($line -like "Users logged in to *") {
            $currentServer = $line.Split()[-1]
        } elseif ($line.StartsWith("SESSION")) {
            return  # Ignore header
        } elseif ($line -ne "" -and $currentServer) {
            $columns = $line -split '\s+'
            if ($columns.Count -ge 3) {  # Ensure there are at least 3 columns
                $session = $columns[0]  # The session is generally in the first column
                $user = $columns[1]  # Get the username

                # Check if the session starts with "ica-cgp#" followed by digits
                if ($session -match "^ica-cgp#\d+$") {
                    if (-not $users.ContainsKey($user)) {
                        $users[$user] = @()
                    }
                    $users[$user] += $currentServer
                }
            }
        }
    }

    # Filter users with multiple connections
    $multipleUsers = @{}
    foreach ($user in $users.Keys) {
        $servers = $users[$user] | Sort-Object -Unique
        if ($servers.Count -gt 1) {
            $multipleUsers[$user] = $servers
        }
    }

    return $multipleUsers
}

# Execute the function to find users with multiple connections
$result = Find-MultipleUsers -file $outputFile

# Write the results to a file
$resultsFile = 'C:\Path\To\Output\result_users.txt'
$outputContent = @()

foreach ($user in $result.Keys) {
    $servers = $result[$user] -join ', '
    $outputContent += "$user is connected on the servers: $servers"
}

Set-Content -Path $resultsFile -Value $outputContent

Write-Host "Results have been written to 'result_users.txt'."
