# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch the script with administrative privileges
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Define a port for the web server (choose a port that's not in use)
$port = 49152

# Start a web server to listen for requests
$listener = New-Object System.Net.HttpListener

# Set up exception handling
try {
    $listener.Prefixes.Add("http://+:$port/")
    $listener.Start()
    Write-Host "Listening for requests on port $port..."

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response

        # Windows API call to turn off the display
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class User32 {
                [DllImport("user32.dll")]
                public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
            }
"@
        $HWND_BROADCAST = 0xFFFF
        $WM_SYSCOMMAND = 0x0112
        $SC_MONITORPOWER = 0xF170
        $POWER_OFF = 0x0002
        [User32]::SendMessage($HWND_BROADCAST, $WM_SYSCOMMAND, $SC_MONITORPOWER, $POWER_OFF)

        # Send a response back to the requester
        $output = [System.Text.Encoding]::UTF8.GetBytes("Display turned off")
        $response.OutputStream.Write($output, 0, $output.Length)
        $response.Close()
    }
}
catch {
    Write-Host "Error: $_"
}
finally {
    $listener.Stop()
    $listener.Close()
}
