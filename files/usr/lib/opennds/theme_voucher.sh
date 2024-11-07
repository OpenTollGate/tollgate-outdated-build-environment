#!/bin/sh
#Copyright (C) The openNDS Contributors 2004-2023
#Copyright (C) BlueWave Projects and Services 2015-2024
#Copyright (C) Francesco Servida 2023
#This software is released under the GNU GPL license.
#
# Warning - shebang sh is for compatibliity with busybox ash (eg on OpenWrt)
# This must be changed to bash for use on generic Linux
#

# Title of this theme:
title="theme_voucher"

# functions:

generate_splash_sequence() {
    login_with_voucher
}

header() {
    # Define a common header html for every page served
    gatewayurl=$(printf "${gatewayurl//%/\\x}")
    echo "<!DOCTYPE html>
		<html>
		<head>
		<meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">
		<meta http-equiv=\"Pragma\" content=\"no-cache\">
		<meta http-equiv=\"Expires\" content=\"0\">
		<meta charset=\"utf-8\">
		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
		<link rel=\"shortcut icon\" href=\"/images/splash.jpg\" type=\"image/x-icon\">
		<link rel=\"stylesheet\" type=\"text/css\" href=\"/splash.css\">
		<title>$gatewayname</title>
		</head>
		<body>
		<div class=\"offset\">
		<div class=\"insert\" style=\"max-width:100%;\">
	"
}


footer() {
    # Define a common footer html for every page served
    year=$(date +'%Y')
    echo "
                       <div style=\"display: flex; align-items: center; margin-top: 20px;\">
                         <img style=\"height:80px; width:80px;\" src=\"$gatewayurl$imagepath\" alt=\"Splash Page: For access to the Internet.\">
                         <div style=\"margin-left: 20px;\">
                           Free as in freedom, not as in beer
			   <br>
			   Using OpenNDS, credit to BlueWave Projects and Services
                         </div>
                       </div>
                       <br><br><br>

		</div>
		</div>
		</div>
		</body>
		</html>

	"

    exit 0
}

login_with_voucher() {
    # This is the simple click to continue splash page with no client validation.
    # The client is however required to accept the terms of service.

    if [ "$tos" = "accepted" ]; then
	#echo "$tos <br>"
	#echo "$voucher <br>"
	voucher_validation
	footer
    fi

    voucher_form
    footer
}

check_voucher() {
    # Strict Voucher Validation for shell escape prevention - Only alphanumeric (and dash character) allowed.
    if echo "${voucher}" | grep -qE '^[[:print:]]+$'; then
        len=$(echo -n "${voucher}" | wc -c)
        if [ "$len" -le 4096 ]; then
	    : #no-op
        else
            echo "Warning: input has a length of $len characters. <br>"
	    : #no-op
        fi
    else
	echo "Invalid input - please report this to TollGate developers. <br>"
	echo "Your input: ${voucher} <br>"
	return 1
    fi

    ##############################################################################################################################
    # WARNING
    # The voucher roll is written to on every login
    # If its location is on router flash, this **WILL** result in non-repairable failure of the flash memory
    # and therefore the router itself. This will happen, most likely within several months depending on the number of logins.
    #
    # The location is set here to be the same location as the openNDS log (logdir)
    # By default this will be on the tmpfs (ramdisk) of the operating system.
    # Files stored here will not survive a reboot.

    voucher_roll="$logdir""vouchers.txt"

    #
    # In a production system, the mountpoint for logdir should be changed to the mount point of some external storage
    # eg a usb stick, an external drive, a network shared drive etc.
    #
    # See "Customise the Logfile location" at the end of this file
    #
    ##############################################################################################################################
    echo "Voucher: $voucher" >> /tmp/theme_voucher_log.md
    echo "Voucher_roll: $voucher_roll" >> /tmp/theme_voucher_log.md
    output=$(grep $voucher $voucher_roll | head -n 1) # Store first occurence of voucher as variable
    #echo "$output <br>" #Matched line
    if [ $(echo -n "$voucher" | grep -ic "cashu") -ge 1 ]; then
	# Compute checksum of voucher and store in variable
	checksum=$(echo -n "$voucher" | sha256sum | cut -d' ' -f1)

	# Use checksum in filename
	ecash_file="/tmp/ecash_${checksum}.md"

        # Read the LNURL from user_inputs.json
        lnurl=$(jq -r '.payout_lnurl' /root/user_inputs.json)

	# Only proceed if the file doesn't exist
	if [ ! -f "$ecash_file" ]; then
            # Echo voucher to file with checksum in name
            echo "$voucher" > "$ecash_file"
	    echo "<p>The e-cash is being processed. Please wait...</p>"

            # Make the curl request using the LNURL from user_inputs.json
            response=$(/www/cgi-bin/./curl_request.sh "$ecash_file" "$lnurl")

	    # Parse the JSON response and check if "paid" is true
	    paid=$(echo "$response" | jq -r '.paid')
	    if [ "$paid" = "true" ]; then
		total_amount=$(echo "$response" | jq -r '.total_amount // 0')
		echo "Redeemed $total_amount SATs successfully! <br>"

		if [ "$total_amount" -gt 0 ]; then
                    current_time=$(date +%s)
		    upload_rate=0
		    download_rate=0
		    upload_quota=0
		    download_quota=0
                    session_length=$total_amount
		    voucher_time_limit=$session_length
                    voucher_expiration=$((current_time + voucher_time_limit))

                    # Log the new temporary voucher
		    echo ${voucher},${upload_rate},${download_rate},${upload_quota},${download_quota},${session_length},${current_time} >> $voucher_roll
                    return 0
		else
		    echo "Failed to redeem e-cash note ${voucher}. <br>"
		    echo "Response from mint: ${response} <br>"
		    echo "Did you press the submit button twice? <br>"
		    echo "Please report issues to the TollGate developers. <br>"
		    return 1
		fi
	    else
		echo "Failed to redeem e-cash note ${voucher}. <br>"
		echo "Response from mint ${response}. <br>"
		echo "Did you press the submit button twice? <br>"
		echo "Please report issues to the TollGate developers. <br>"
		return 1
	    fi

	else
	    echo "E-cash note was already submitted, please wait for mint to respond. <br>"
	fi

    elif [ $(echo -n "$voucher" | grep -ic "lnurlw") -ge 1 ]; then

	# Compute checksum of voucher and store in variable
	checksum=$(echo -n "$voucher" | sha256sum | cut -d' ' -f1)

	# Use checksum in filename
	lnurlw_file="/tmp/lnurl_${clientmac}_${checksum}.md"
	echo "$voucher" > "$lnurlw_file"

	amount="8000"

	response=$(/www/cgi-bin/./redeem_lnurlw.sh "$lnurlw_file" "$amount" "$lnurl")
	# Expecting: {"status":"OK", "paid_amount":256000}

	# Parse the JSON response and check if "status" is "OK"
	status=$(echo "$response" | jq -r '.status')
	paid_amount=$(echo "$response" | jq -r '.paid_amount // 0')

	if [ "$status" = "OK" ] && [ "$paid_amount" -gt 0 ]; then
            echo "Voucher entered was ${voucher}. This looks like an lnurlw note that was redeemed successfully. <br>"

            current_time=$(date +%s)
            upload_rate=512    # Define rates for authenticated session
            download_rate=512  # Define rates for authenticated session
            upload_quota=10240
            download_quota=10240
            session_length=($paid_amount) / 1000

            voucher_time_limit=$session_length
            voucher_expiration=$(($current_time + $voucher_time_limit))

            # Log the voucher
            session_length=$voucher_time_limit
            echo ${voucher},${upload_rate},${download_rate},${upload_quota},${download_quota},${session_length},${current_time} >> $voucher_roll

            return 0
	else
            echo "Failed to redeem LNURLW note ${voucher}. <br>"
            echo "Response from LNBits: ${response} <br>"
            echo "Please report issues to the TollGate developers. <br>"
            return 1
	fi
    else
	echo "No Voucher Found - Retry <br>"
	return 1
    fi
    
    # Should not get here
    return 1
}

voucher_validation() {
    originurl=$(printf "${originurl//%/\\x}")

    check_voucher
    if [ $? -eq 0 ]; then
	#echo "Voucher is Valid, click Continue to finish login<br>"

	# Refresh quotas with ones imported from the voucher roll.
	quotas="$session_length $upload_rate $download_rate $upload_quota $download_quota"
	# Set voucher used (useful if for accounting reasons you track who received which voucher)
	userinfo="$title - $voucher"

	# Authenticate and write to the log - returns with $ndsstatus set
	auth_log

	# output the landing page - note many CPD implementations will close as soon as Internet access is detected
	# The client may not see this page, or only see it briefly
	auth_success="
			<p>
				<hr>
			</p>
			Granted $session_length minutes of internet access.
			<hr>
			<p>
				<italic-black>
					You can use your Browser, Email and other network Apps as you normally would.
				</italic-black>
			</p>
			<p>
				Your device originally requested <b>$originurl</b>
				<br>
				Click or tap Continue to go to there.
			</p>
			<form>
				<input type=\"button\" VALUE=\"Continue\" onClick=\"location.href='$originurl'\" >
			</form>
			<hr>
		"
	auth_fail="
			<p>
				<hr>
			</p>
			<hr>
			<p>
				<italic-black>
					You need to make a successful payment to connect with the internet.
				</italic-black>
			</p>
			<p>
				<br>
				Click or tap Continue to try again.
			</p>
			<form>
				<input type=\"button\" VALUE=\"Continue\" onClick=\"location.href='$originurl'\" >
			</form>
			<hr>
		"

	if [ "$ndsstatus" = "authenticated" ]; then
	    echo "$auth_success"
	else
	    echo "$auth_fail"
	fi
    else
	echo "<big-red>Payment failed, click Continue to restart login<br></big-red>"
	echo "
			<form>
				<input type=\"button\" VALUE=\"Continue\" onClick=\"location.href='$originurl'\" >
			</form>
		"
    fi

    # Serve the rest of the page:
    footer
}

voucher_form() {
    # Define a click to Continue form

    # From openNDS v10.2.0 onwards, QL code scanning is supported to pre-fill the "voucher" field in this voucher_form page.
    #
    # The QL code must be of the link type and be of the following form:
    #
    # http://[gatewayfqdn]/login?voucher=[voucher_code]
    #
    # where [gatewayfqdn] defaults to status.client (can be set in the config)
    # and [voucher_code] is of course the unique voucher code for the current user

    # Get the voucher code:

    voucher_code=$(echo "$cpi_query" | awk -F "voucher%3d" '{printf "%s", $2}' | awk -F "%26" '{printf "%s", $1}')

    echo "
        <med-blue>
            Users must pay for their infrastructure! If not you, then who?
        </med-blue><br>
        <hr>
        Your IP: $clientip <br>
        Your MAC: $clientmac <br>
        <hr>
        <form action=\"/opennds_preauth/\" method=\"get\">
            <input type=\"hidden\" name=\"fas\" value=\"$fas\">
            <input type=\"hidden\" name=\"tos\" value=\"accepted\">
            Only accepting notes from minibits.cash <br>
            Pay here: <input type=\"text\" name=\"voucher\" value=\"$voucher_code\" required> <input type=\"submit\" value=\"Connect\" >
        </form>
        <br>

	<hr>
    "

    footer
}


#### end of functions ####


#################################################
#						#
#  Start - Main entry point for this Theme	#
#						#
#  Parameters set here overide those		#
#  set in libopennds.sh			#
#						#
#################################################

# Quotas and Data Rates
#########################################
# Set length of session in minutes (eg 24 hours is 1440 minutes - if set to 0 then defaults to global sessiontimeout value):
# eg for 100 mins:
# session_length="100"
#
# eg for 20 hours:
# session_length=$((20*60))
#
# eg for 20 hours and 30 minutes:
# session_length=$((20*60+30))
session_length="0"

# Set Rate and Quota values for the client
# The session length, rate and quota values could be determined by this script, on a per client basis.
# rates are in kb/s, quotas are in kB. - if set to 0 then defaults to global value).
upload_rate="0"
download_rate="0"
upload_quota="0"
download_quota="0"

quotas="$session_length $upload_rate $download_rate $upload_quota $download_quota"

# Define the list of Parameters we expect to be sent sent from openNDS ($ndsparamlist):
# Note you can add custom parameters to the config file and to read them you must also add them here.
# Custom parameters are "Portal" information and are the same for all clients eg "admin_email" and "location" 
ndscustomparams=""
ndscustomimages=""
ndscustomfiles=""

ndsparamlist="$ndsparamlist $ndscustomparams $ndscustomimages $ndscustomfiles"

# The list of FAS Variables used in the Login Dialogue generated by this script is $fasvarlist and defined in libopennds.sh
#
# Additional custom FAS variables defined in this theme should be added to $fasvarlist here.
additionalthemevars="tos voucher"

fasvarlist="$fasvarlist $additionalthemevars"

# You can choose to define a custom string. This will be b64 encoded and sent to openNDS.
# There it will be made available to be displayed in the output of ndsctl json as well as being sent
#	to the BinAuth post authentication processing script if enabled.
# Set the variable $binauth_custom to the desired value.
# Values set here can be overridden by the themespec file

#binauth_custom="This is sample text sent from \"$title\" to \"BinAuth\" for post authentication processing."

# Encode and activate the custom string
#encode_custom

# Set the user info string for logs (this can contain any useful information)
userinfo="$title"

##############################################################################################################################
# Customise the Logfile location.
##############################################################################################################################
#Note: the default uses the tmpfs "temporary" directory to prevent flash wear.
# Override the defaults to a custom location eg a mounted USB stick.
#mountpoint="/mylogdrivemountpoint"
#logdir="$mountpoint/ndslog/"
#logname="ndslog.log"
