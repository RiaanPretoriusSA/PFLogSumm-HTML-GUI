#!/usr/bin/env bash
# Debug option - should be disabled unless required
#set -x


#Get Command Line Parameters for the custom date e.g.  -d "Nov 03"
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--date)
    CUSTOMDATE="$2"
    shift # past argument
    shift # past value
    ;;

    -l|--logfile)
    CUSTOMLOG="$2"
    shift # past argument
    shift # past value
    ;;

    -m|--month)
    CUSTOMMONTH="$2"
    shift # past argument
    shift # past value
    ;;    

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#Select Temporal
if [[ -z "${CUSTOMMONTH}" ]]; then
    #If custom date is not set - default to current date e.g. 'Dec  9'
    if [[ -z "${CUSTOMDATE}" ]]; then
        LOGDATE=$(date +'%b %e')
    else
        LOGDATE=$CUSTOMDATE
    fi
else
    LOGDATE=$( echo ${CUSTOMMONTH} | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
fi

#Custom Log file(s)
if [[ -z "${CUSTOMLOG}" ]]; then
    LOGFILELOCATION="/var/log/maillog"
else
    LOGFILELOCATION=${CUSTOMLOG}
fi

#Test for a valid log file
if ! ls $LOGFILELOCATION 1> /dev/null 2>&1; then
    echo "Not a valid log file"; exit 1ß
fi



#Temporal Values
REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTYEAR=$(date +'%Y')
CURRENTMONTH=$(date +'%b')
CURRENTDAY=$(date +'%e')


#Get Counts


Sent=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c 'postfix/smtp.*status=sent' )
Dfr=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c 'postfix/smtp.*status=deferred' )
Bnc=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c 'postfix/smtp.*status=bounce' )
RelayAccDnd=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c 'postfix/smtp.*Relay access denied' )
EnvelopeBlocked=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c -E '*550.*Envelope blocked' )

greylist=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c 'postfix/smtp.*[Gg]reylist' )
Received=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c 'postfix/smtpd.*client=' )
Rejected=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c -oP 'rejected: \K.*' )
SpamCount=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c 'status=sent.*spam' )
MailVirus=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c -i 'infected' )

PREGREET=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep 'postfix/postscreen' | grep  -c 'PREGREET' )
CONNECT=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep 'postfix/postscreen' | grep  -c 'CONNECT' )
DISCONNECT=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep 'postfix/postscreen' | grep  -c 'DISCONNECT' )
HANGUP=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep 'postfix/postscreen' | grep  -c 'HANGUP' )
DNSBL=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep 'postfix/postscreen' | grep  -c 'DNSBL' )
AccountLogins=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep  -c  'postfix/.*sasl_username' )

warning=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c -i 'warning' )
error=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c -i 'error' )
fatal=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c -i 'fatal' )
panic=$( grep  "$LOGDATE" $LOGFILELOCATION 2>/dev/null | grep -c -i 'panic' )

echo "Report Run       : $REPORTDATE"
echo "Log Date Extract : $LOGDATE"

echo '-------------------------------------------'
echo "Total Messages Delivered    : $Sent"
echo "Total Messages Deferred     : $Dfr"
echo "Total Messages Bounced      : $Bnc"
echo "Total Messages Rejected     : $Rejected"
echo "Total Messages Received     : $Received"
echo "Total Relay Access Denied   : $RelayAccDnd"
echo "Total Greylisted            : $greylist"
echo "Total Virus                 : $MailVirus"
echo "Total Spam                  : $SpamCount"

echo "Envelope Blocked (550)      : $EnvelopeBlocked"
echo "SASL Account Logins         : $AccountLogins"

echo "Total postscreen PREGREETS  : $PREGREET"
echo "Total postscreen CONNECT    : $CONNECT"
echo "Total postscreen DISCONNECT : $DISCONNECT"
echo "Total postscreen HANGUP     : $HANGUP"
echo "Total postscreen DNSBL      : $DNSBL"

echo "Postfix Warnings            : $warning"
echo "Postfix Errors              : $error"
echo "Postfix Fatal               : $fatal"
echo "Postfix Panic               : $panic"


echo




exit 0


 #if ($l =~ m/status=bounced/i) {$rBnc++;}
 if ($l =~ m/postfix\/pickup/i) {
  if ($l =~ m/uid=|sender=/) {$rRcv++;}
  }
 if ($l =~ m/client=/i) {$rRcv++;}
 if ($l =~ m/reject:/i) {$rRjc++;}
 if ($l =~ m/hold:/i) {$rHld++;}
 if ($l =~ m/discard:/i) {$rDsc++;}
 }

#print "Message.Delivered: Total delivered messages: $rDlv\n";
#print "Statistic.Delivered: $rDlv\n";
print "Message.Forwarded: Total forwarded messages: $rFwd\n";
print "Statistic.Forwarded: $rFwd\n";
print "Message.Rejected: Total rejected messages: $rRjc\n";
print "Statistic.Rejected: $rRjc\n";
print "Message.Received: Total received messages: $rRcv\n";
print "Statistic.Received: $rRcv\n";
print "Message.Discarded: Total discarded messages: $rDsc\n";
print "Statistic.Discarded: $rDsc\n";
#print "Message.Deferred: Total deferred messages: $rDfr\n";
#print "Statistic.Deferred: $rDfr\n";
print "Message.Bounced: Total bounced messages: $rBnc\n";
print "Statistic.Bounced: $rBnc\n";
print "Message.Held: Total held messages: $rHld\n";
print "Statistic.Held: $rHld\n";
