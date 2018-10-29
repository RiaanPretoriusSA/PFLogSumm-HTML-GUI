#!/usr/bin/env bash

#=====================================================================================================================
#   DESCRIPTION  Generating a stand alone web report for postix log files, 
#                Runs on all Linux platforms with postfix installed
#   AUTHOR       Riaan Pretorius <pretorius.riaan@gmail.com>
#   IDIOCRACY    yes.. i know.. bash??? WTF was i thinking?? Well it works, runs every 
#                where and it is portable
#
#   https://en.wikipedia.org/wiki/MIT_License
#
#   LICENSE
#   MIT License
#
#   Copyright (c) 2018 Riaan Pretorius
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
#   and associated documentation files  (the "Software"), to deal in the Software without restriction, 
#   including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
#   and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
#   subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all copies or substantial 
#   portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
#   NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
#   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
#   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION  WITH THE SOFTWARE 
#   OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#=====================================================================================================================

#LOGFILE="/var/log/maillog*"
LOGFILE="maillog*"
PFLOGSUMMBIN="/usr/sbin/pflogsumm --verbose_msg_detail --zero_fill "
HTMLOUTPUTDIR="/var/www/html/"
HTMLOUTPUTFILENAME="index.html"

REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
ACTIVEHOSTNAME=$(cat /proc/sys/kernel/hostname)

#echo "Generating pflogsumm report"
$PFLOGSUMMBIN -e $LOGFILE > /tmp/mailreport


#Extract Sections from PFLOGSUMM
sed -n '/^Grand Totals/,/^Per-Day/p;/^Per-Day/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,3ba' -e 'P;D' | sed '/^$/d' > /tmp/GrandTotals
sed -n '/^Per-Day Traffic Summary/,/^Per-Hour/p;/^Per-Hour/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/PerDayTrafficSummary
sed -n '/^Per-Hour Traffic Daily Average/,/^Host\//p;/^Host\//q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/PerHourTrafficDailyAverage
sed -n '/^Host\/Domain Summary\: Message Delivery/,/^Host\/Domain Summary\: Messages Received/p;/^Host\/Domain Summary\: Messages Received/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/HostDomainSummaryMessageDelivery
sed -n '/^Host\/Domain Summary\: Messages Received/,/^Senders by message count/p;/^Senders by message count/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/HostDomainSummaryMessagesReceived
sed -n '/^Senders by message count/,/^Recipients by message count/p;/^Recipients by message count/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Sendersbymessagecount
sed -n '/^Recipients by message count/,/^Senders by message size/p;/^Senders by message size/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Recipientsbymessagecount
sed -n '/^Senders by message size/,/^Recipients by message size/p;/^Recipients by message size/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Sendersbymessagesize
sed -n '/^Recipients by message size/,/^Messages with no size data/p;/^Messages with no size data/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Recipientsbymessagesize
sed -n '/^Messages with no size data/,/^message deferral detail/p;/^message deferral detail/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Messageswithnosizedata
sed -n '/^message deferral detail/,/^message bounce detail (by relay)/p;/^message bounce detail (by relay)/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/messagedeferraldetail
sed -n '/^message bounce detail (by relay)/,/^message reject detail/p;/^message reject detail/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/messagebouncedetaibyrelay
sed -n '/^Warnings/,/^Fatal Errors/p;/^Fatal Errors/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/warnings

sed -n '/^Fatal Errors/,/^Master daemon messages/p;/^Master daemon messages/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/FatalErrors


#======================================================
# Extract Information into variables -> Grand Totals
#======================================================
ReceivedEmail=$(awk '$2=="received" {print $1}'  /tmp/GrandTotals)
DeliveredEmail=$(awk '$2=="delivered" {print $1}'  /tmp/GrandTotals)
ForwardedEmail=$(awk '$2=="forwarded" {print $1}'  /tmp/GrandTotals)
DeferredEmailCount=$(awk '$2=="deferred" {print $1}'  /tmp/GrandTotals)
DeferredEmailDeferralsCount=$(awk '$2=="deferred" {print $3" "$4}'  /tmp/GrandTotals)
BouncedEmail=$(awk '$2=="bounced" {print $1}'  /tmp/GrandTotals)
RejectedEmailCount=$(awk '$2=="rejected" {print $1}'  /tmp/GrandTotals)
RejectedEmailPercentage=$(awk '$2=="rejected" {print $3}'  /tmp/GrandTotals)
RejectedWarningsEmail=$(sed 's/reject warnings/rejectwarnings/' /tmp/GrandTotals | awk '$2=="rejectwarnings" {print $1}')
HeldEmail=$(awk '$2=="held" {print $1}'  /tmp/GrandTotals)
DiscardedEmailCount=$(awk '$2=="discarded" {print $1}'  /tmp/GrandTotals)
DiscardedEmailPercentage=$(awk '$2=="discarded" {print $3}'  /tmp/GrandTotals)
BytesReceivedEmail=$(sed 's/bytes received/bytesreceived/' /tmp/GrandTotals | awk '$2=="bytesreceived" {print $1}'|sed 's/[^0-9]*//g' )
BytesDeliveredEmail=$(sed 's/bytes delivered/bytesdelivered/' /tmp/GrandTotals | awk '$2=="bytesdelivered" {print $1}'|sed 's/[^0-9]*//g')
SendersEmail=$(awk '$2=="senders" {print $1}'  /tmp/GrandTotals)
SendingHostsDomainsEmail=$(sed 's/sending hosts\/domains/sendinghostsdomains/' /tmp/GrandTotals | awk '$2=="sendinghostsdomains" {print $1}')
RecipientsEmail=$(awk '$2=="recipients" {print $1}'  /tmp/GrandTotals)
RecipientHostsDomainsEmail=$(sed 's/recipient hosts\/domains/recipienthostsdomains/' /tmp/GrandTotals | awk '$2=="recipienthostsdomains" {print $1}')


#======================================================
# Extract Information into variable -> Per-Day Traffic Summary
#======================================================
 PerDayTrafficSummaryTable=""
while IFS= read -r var
do
 PerDayTrafficSummaryTable+="<tr>"
 PerDayTrafficSummaryTable+=$(echo "$var" | awk '{print "<td>"$1" "$2" "$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>""<td>"$7"</td>""<td>"$8"</td>"}')
 PerDayTrafficSummaryTable+="</tr>"
done < /tmp/PerDayTrafficSummary
echo $PerDayTrafficSummaryTable > /tmp/PerDayTrafficSummary


#======================================================
# Extract Information into variable -> Per-Hour Traffic Daily Average
#======================================================
 PerHourTrafficDailyAverageTable=""
while IFS= read -r var
do
 PerHourTrafficDailyAverageTable+="<tr>"
 PerHourTrafficDailyAverageTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>"}')
 PerHourTrafficDailyAverageTable+="</tr>"
done < /tmp/PerHourTrafficDailyAverage
echo $PerHourTrafficDailyAverageTable > /tmp/PerHourTrafficDailyAverage




#======================================================
# Extract Information into variable -> Per-Hour Traffic Daily Average
#======================================================
 HostDomainSummaryMessageDeliveryTable=""
while IFS= read -r var
do
 HostDomainSummaryMessageDeliveryTable+="<tr>"
 HostDomainSummaryMessageDeliveryTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4" "$5"</td>""<td>"$6" "$7"</td>""<td>"$8"</td>" }')
 HostDomainSummaryMessageDeliveryTable+="</tr>"
done < /tmp/HostDomainSummaryMessageDelivery
echo $HostDomainSummaryMessageDeliveryTable > /tmp/HostDomainSummaryMessageDelivery


#======================================================
# Extract Information into variable -> Host Domain Summary Messages Received
#======================================================
 HostDomainSummaryMessagesReceivedTable=""
while IFS= read -r var
do
 HostDomainSummaryMessagesReceivedTable+="<tr>"
 HostDomainSummaryMessagesReceivedTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>"}')
 HostDomainSummaryMessagesReceivedTable+="</tr>"
done < /tmp/HostDomainSummaryMessagesReceived
echo $HostDomainSummaryMessagesReceivedTable > /tmp/HostDomainSummaryMessagesReceived


#======================================================
# Extract Information into variable -> Host Domain Summary Messages Received
#======================================================
 SendersbymessagecountTable=""
while IFS= read -r var
do
 SendersbymessagecountTable+="<tr>"
 SendersbymessagecountTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
 SendersbymessagecountTable+="</tr>"
done < /tmp/Sendersbymessagecount
echo $SendersbymessagecountTable > /tmp/Sendersbymessagecount

#======================================================
# Extract Information into variable -> Recipients by message count
#======================================================
 RecipientsbymessagecountTable=""
while IFS= read -r var
do
 RecipientsbymessagecountTable+="<tr>"
 RecipientsbymessagecountTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
 RecipientsbymessagecountTable+="</tr>"
done < /tmp/Recipientsbymessagecount
echo $RecipientsbymessagecountTable > /tmp/Recipientsbymessagecount


#======================================================
# Extract Information into variable -> Senders by message size
#======================================================
 SendersbymessagesizeTable=""
while IFS= read -r var
do
 SendersbymessagesizeTable+="<tr>"
 SendersbymessagesizeTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
 SendersbymessagesizeTable+="</tr>"
done < /tmp/Sendersbymessagesize
echo $SendersbymessagesizeTable > /tmp/Sendersbymessagesize


#======================================================
# Extract Information into variable -> Recipients by messagesize Table
#======================================================
 RecipientsbymessagesizeTable=""
while IFS= read -r var
do
 RecipientsbymessagesizeTable+="<tr>"
 RecipientsbymessagesizeTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
 RecipientsbymessagesizeTable+="</tr>"
done < /tmp/Recipientsbymessagesize
echo $RecipientsbymessagesizeTable > /tmp/Recipientsbymessagesize


#======================================================
# Extract Information into variable -> Recipients by messagesize Table
#======================================================
 MessageswithnosizedataTable=""
while IFS= read -r var
do
 MessageswithnosizedataTable+="<tr>"
 MessageswithnosizedataTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
 MessageswithnosizedataTable+="</tr>"
done < /tmp/Messageswithnosizedata
echo $MessageswithnosizedataTable > /tmp/Messageswithnosizedata





#======================================================
# Single PAGE HTML TEMPLATE
# Using embedded HTML makes the script highly portable
# SED search and replace tags to fill the content
#======================================================

cat > $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME << 'HTMLTEMPLATEOUT'



HTMLTEMPLATEOUT



#======================================================
# Replace Placeholders with values - GrandTotals
#======================================================
sed -i "s/##REPORTDATE##/$REPORTDATE/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##ACTIVEHOSTNAME##/$ACTIVEHOSTNAME/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##ReceivedEmail##/$ReceivedEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##DeliveredEmail##/$DeliveredEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##ForwardedEmail##/$ForwardedEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##DeferredEmailCount##/$DeferredEmailCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##DeferredEmailDeferralsCount##/$DeferredEmailDeferralsCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##BouncedEmail##/$BouncedEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##RejectedEmailCount##/$RejectedEmailCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##RejectedEmailPercentage##/$RejectedEmailPercentage/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##RejectedWarningsEmail##/$RejectedWarningsEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##HeldEmail##/$HeldEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##DiscardedEmailCount##/$DiscardedEmailCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##DiscardedEmailPercentage##/$DiscardedEmailPercentage/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##BytesReceivedEmail##/$BytesReceivedEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##BytesDeliveredEmail##/$BytesDeliveredEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##SendersEmail##/$SendersEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##SendingHostsDomainsEmail##/$SendingHostsDomainsEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##RecipientsEmail##/$RecipientsEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME
sed -i "s/##RecipientHostsDomainsEmail##/$RecipientHostsDomainsEmail/g" $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME

#======================================================
# Replace Placeholders with values - Table PerDayTrafficSummaryTable
#======================================================
sed -i '/##PerDayTrafficSummaryTable##/ {
r /tmp/PerDayTrafficSummary
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 


#======================================================
# Replace Placeholders with values - Table PerHourTrafficDailyAverageTable
#======================================================
sed -i '/##PerHourTrafficDailyAverageTable##/ {
r /tmp/PerHourTrafficDailyAverage
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 


#======================================================
# Replace Placeholders with values - Table HostDomainSummaryMessageDelivery
#======================================================
sed -i '/##HostDomainSummaryMessageDelivery##/ {
r /tmp/HostDomainSummaryMessageDelivery
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values - Table HostDomainSummaryMessagesReceived
#======================================================
sed -i '/##HostDomainSummaryMessagesReceived##/ {
r /tmp/HostDomainSummaryMessagesReceived
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values - Table Sendersbymessagecount
#======================================================
sed -i '/##Sendersbymessagecount##/ {
r /tmp/Sendersbymessagecount
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values - Table RecipientsbyMessageCount
#======================================================
sed -i '/##RecipientsbyMessageCount##/ {
r /tmp/Recipientsbymessagecount
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values - Table SendersbyMessageSize
#======================================================
sed -i '/##SendersbyMessageSize##/ {
r /tmp/Sendersbymessagesize
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values - Table Recipientsbymessagesize
#======================================================
sed -i '/##Recipientsbymessagesize##/ {
r /tmp/Recipientsbymessagesize
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values - Table Messageswithnosizedata
#======================================================
sed -i '/##Messageswithnosizedata##/ {
r /tmp/Messageswithnosizedata
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 


#======================================================
# Replace Placeholders with values -  MessageDeferralDetail
#======================================================
sed -i '/##MessageDeferralDetail##/ {
r /tmp/messagedeferraldetail
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 

#======================================================
# Replace Placeholders with values -  MessageBounceDetailbyrelay
#======================================================
sed -i '/##MessageBounceDetailbyrelay##/ {
r /tmp/messagebouncedetaibyrelay
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 


#======================================================
# Replace Placeholders with values - warnings
#======================================================
sed -i '/##MailWarnings##/ {
r /tmp/warnings
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 


#======================================================
# Replace Placeholders with values - FatalErrors
#======================================================
sed -i '/##MailFatalErrors##/ {
r /tmp/FatalErrors
d
}' $HTMLOUTPUTDIR/$HTMLOUTPUTFILENAME 





#======================================================
# Clean UP
#======================================================
