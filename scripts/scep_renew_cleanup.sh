#!/bin/sh

# Inspired by https://community.jamf.com/t5/jamf-pro/ad-certificate-auto-renewal-workflow/m-p/155204/highlight/true#M144228

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Script must be run as root" 1>&2
    exit 1
fi

# Set locale to C to avoid issues with date formatting
export LC_TIME=C

# Some Variables
## Path to log file
LOG_PATH="/Library/Logs/ScepRenew.log"
## The identifier of the configuration profile containing the SCEP Payload
PROFILE_IDENTIFIER=""
## How long before expiration to trigger renewal (in seconds)
EXP_TRESHOLD=864000
## Host to check for connectivity
PINGHOST="1.1.1.1"
# Current Epoch time
now=$(date "+%s")
##
## Common name
## If your MDM can push the script and add variables, just put here the variable name that you used
## With Mosyle for example, if I need to use the user email for 1:1 devices, I can set CN=%Email%
## If you don't have this capability with your MDM but all your 1:1 devices are getting the user email as a CN, you can just set CN="@yourdomain.com"
## Another option would be to use the device UUID if devices are not 1:1, in that case CN=$(ioreg -ad2 -c IOPlatformExpertDevice | plutil -extract IORegistryEntryChildren.0.IOPlatformUUID raw -)
##
CN="@yourdomain.com"


# Echo function
echoFunc ()
{
    # Date and Time function for the log file
    fDateTime () { echo $(date +"%a %b %d %T"); }

    # Title for beginning of line in log file
    Title="ScepRenew:"

    # Header string function
    fHeader () { echo $(fDateTime) $(hostname) $Title; }

    # Check for the log file, and write to it
    if [ -e $LOG_PATH ]; then
        echo $(fHeader) "$1" >> $LOG_PATH
    else
        cat > $LOG_PATH &
        cat $LOG_PATH
        if [ -e $LOG_PATH ]; then
            echo $(fHeader) "$1" >> $LOG_PATH
        else
            echo "Failed to create log file"
            exit 1
        fi
    fi

    # Echo out, uncomment if you're running the script manually and need to see output
    # echo $(fHeader) "$1"
}

echoFunc "======================== Starting Script ========================"

if !( ping -c1 $PINGHOST &>/dev/null )
then
    echoFunc "The mac must be online to run this script, exiting"
    exit 1
fi


echoFunc "Searching certificates with the following CN: $CN"
# Count the number of machine certificates currently on the device
Certs=$(security find-certificate -apZ -c $CN "/Library/Keychains/System.keychain")
CertCount=$(grep SHA-1 <<< $Certs | wc | awk '{print $1}')

# In case no cert was found, exit
if [ $CertCount == 0 ]; then
    # No machine certificate was found
    echoFunc "No certificate found, exiting"
    exit 1
fi

# Find the certificate expiration date (this will return only the one with the latest expiration date, even if there are more than 1)
LatestCert=$(sed -n 'H; /^SHA-1/h; ${g;p;}' <<< "$Certs")
CertExp=$(openssl x509 -noout -enddate 2>/dev/null <<< "$LatestCert" | cut -f2 -d=)
CertSer=$(openssl x509 -noout -serial 2>/dev/null <<< "$LatestCert" | cut -f2 -d=)
# Log current certificate expiration date
dateformat=$(date -j -f "%b %d %T %Y %Z" "$CertExp" "+%b %d %Y")
echoFunc "Found certificate with serial $CertSer expiring on $dateformat"
# Convert expiration date in epoch time
certExpEpoch=$(date -j -f "%b %d %T %Y %Z" "$CertExp" "+%s")
# Calculate how long until expiration in seconds
expDiff=$(expr $certExpEpoch - $now)

# If less than treshold, renew the certificate
if [ $expDiff -le $EXP_TRESHOLD ];
then
    echoFunc "Expiration treshold was reached, attempting to renew"
    res=$(profiles renew -type configuration -identifier $PROFILE_IDENTIFIER)
    #echoFunc "Certificate Renewed"
    echoFunc "$res"
fi 


# Count the number of machine certificates currently on the device
CertCount=$(security find-certificate -apZ -c $CN "/Library/Keychains/System.keychain" | grep SHA-1 | wc | awk '{print $1}')

if [ $CertCount > 1 ]; then
        # Multiple machine certificates were found
        echoFunc "Number of certificates found: $CertCount"

        # Delete the old certificates
        Tail=$CertCount
        while [ $Tail -ge 2 ]
        do
            Certs=$(security find-certificate -apZ -c $CN "/Library/Keychains/System.keychain" | grep SHA-1 | awk '{print $3}' | tail -r | tail "+$Tail" | tail -r)
            echoFunc "Deleting certificate with SHA-1: $Certs"
            security delete-certificate -Z $Certs /Library/Keychains/System.keychain &2>/dev/null
            Tail=$(expr $Tail - 1)
        done

    # Find the new certificate expiration date
        CertExp=$(security find-certificate -apZ -c $CN "/Library/Keychains/System.keychain" | sed -n 'H; /^SHA-1/h; ${g;p;}' | openssl x509 -noout -enddate 2>/dev/null | cut -f2 -d=)
        dateformat=$(date -j -f "%b %d %T %Y %Z" "$CertExp" "+%b %d %Y")
        echoFunc "Computer certificate expiration: $dateformat"
        #/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -button1 "OK" -defaultButton 1 -icon /Applications/Utilities/Keychain Access.app/Contents/Resources/AppIcon.icns -timeout 30 -title "New Machine Certificate" -description "Your new machine certificate expires on: $dateformat. Please make note of this. This window will close in 30 seconds."
fi

echoFunc "Exit code: $?"
echoFunc "======================== Script Complete ========================"
exit $?