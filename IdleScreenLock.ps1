<#
.SYNOPSIS
    Monitors for keyboard/mouse activity and locks the user session after a defined period of inactivity
.DESCRIPTION
    Monitors for keyboard/mouse activity and locks the user session after a defined period of inactivity
    Some applications will stop Windows from going to screensaver/locking the users screen (MobaXTerm was our culprit).
    This script ignores user preferences and will lock and turn off the screen after a defined period.
.PARAMETER IdleTime
    Length of time (in seconds) to wait before locking an idle session. Default 600 seconds
.NOTES
    Name: Lock-IdleScreen
    Author: David Bell
    DateCreated: 05/08/2015
.EXAMPLE
IdleScreenLock -IdleTime 600
#>
param(
    [int]$IdleTime = 600
)


# Define .Net functions to get IdleTime
Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

# Define DLL connection to lock screen
$signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool LockWorkStation();
"@
$LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru

# Define function to turn monitors off when not in use
Function ScreenOff
{
   #http://powershell.com/cs/forums/t/13602.aspx
   #turn off display by
   # DefWindowProc(hWnd,WM_SYSCOMMAND, SC_MONITORPOWER, 2)
   # WM_SYSCOMMAND    0x0112
   #SC_MONITORPOWER = 0xF170

   #monitor state =  2 (shut off)
   #monitor state =  1 (low power)
   #monitor state = -1 (display is being turned on)

   add-type -TypeDefinition '
   using System;
   using System.Runtime.InteropServices;

   namespace ___Display {
           public class TurnOff {
                   [DllImport("user32.dll")]
                   public static extern IntPtr DefWindowProc(IntPtr hWnd, uint  uMsg, IntPtr wParam, IntPtr lParam);
                   
                   [DllImport("user32.dll", SetLastError = false)]
                   public static extern IntPtr GetDesktopWindow();
           }
   }
   '
   $o = [___Display.TurnOff]
   $handle = $o::GetDesktopWindow()
   $o::DefWindowProc( $handle, 0x0112, 0xF170, 2 ) > $null 
}

while ( $true ) {
    # Check if the time since last user input was greater than 2 * IdleTime ago
    if ([PInvoke.Win32.UserInput]::IdleTime.TotalSeconds -gt $(2*$IdleTime))
    {
        # The workstation should already be locked; Sleep the monitors and wait for next check cycle
        ScreenOff
        Start-Sleep -Seconds $($IdleTime)
    }
    # Check if the time since last user input was greater than IdleTime ago
    elseif ([PInvoke.Win32.UserInput]::IdleTime.TotalSeconds -gt $IdleTime)
    {
        # Lock-WorkStation
        $LockWorkStation::LockWorkStation() | Out-Null
        # Wait 5 seconds then turn off the screens
        # We wait here because the screens take a moment to turn on/off and it would be annoying if you were actually sitting at your PC when it did this
        Start-Sleep -Seconds 5
        ScreenOff

        # Wait for next check cycle
        Start-Sleep -Seconds $($IdleTime)
    }
    else
    {
        # Sleep for the remaining IdleTime before checking again
        Start-Sleep -Seconds $($IdleTime - [PInvoke.Win32.UserInput]::IdleTime.TotalSeconds)
    }
}
