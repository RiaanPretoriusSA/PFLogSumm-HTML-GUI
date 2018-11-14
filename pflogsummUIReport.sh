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

#CONFIG FILE LOCATION
PFSYSCONFDIR="/etc"

#Create Blank Config File if it does not exist
if [ ! -f ${PFSYSCONFDIR}/"pflogsumui.conf" ]
then
tee ${PFSYSCONFDIR}/"pflogsumui.conf" <<EOF
#PFLOGSUMUI CONFIG

##  Postfix Log Location
LOGFILELOCATION="/var/www/html/maillog"

##  pflogsumm details
PFLOGSUMMOPTIONS=" --verbose_msg_detail --zero_fill "
PFLOGSUMMBIN="/usr/sbin/pflogsumm  "

##  HTML Output
HTMLOUTPUTDIR="/var/www/html/"
HTMLOUTPUTFILENAME="index.html"

EOF
fi

#Load Config File
. ${PFSYSCONFDIR}/"pflogsumui.conf"


REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
ACTIVEHOSTNAME=$(cat /proc/sys/kernel/hostname)

$PFLOGSUMMBIN $PFLOGSUMMOPTIONS  -e $LOGFILELOCATION > /tmp/mailreport


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

<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="">
    <meta name="author" content="">
    <link rel="icon" href="../../../../favicon.ico">

    <title>Postfix Report Dashboard</title>

    <!-- Bootstrap core CSS -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.4.2/css/all.css" integrity="sha384-/rXc/GQVaYpyDdyxK+ecHPVYJSN9bmVFBvjA/9eOB+pb3F2w2N6fc5qB9Ew5yIns"
        crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/themes/prism.css">

    <style>
        html,
        body {
            overflow-x: hidden;
            /* Prevent scroll on narrow devices */
        }

        body {
            padding-top: 56px;
        }

        @media (max-width: 991.98px) {
            .offcanvas-collapse {
                position: fixed;
                top: 56px;
                /* Height of navbar */
                bottom: 0;
                left: 100%;
                width: 100%;
                padding-right: 1rem;
                padding-left: 1rem;
                overflow-y: auto;
                visibility: hidden;
                background-color: #343a40;
                transition-timing-function: ease-in-out;
                transition-duration: .3s;
                transition-property: left, visibility;
            }


        }

        .nav-scroller {
            position: relative;
            z-index: 2;
            height: 2.75rem;
            overflow-y: hidden;
        }

        .nav-scroller .nav {
            display: -ms-flexbox;
            display: flex;
            -ms-flex-wrap: nowrap;
            flex-wrap: nowrap;
            padding-bottom: 1rem;
            margin-top: -1px;
            overflow-x: auto;
            color: rgba(255, 255, 255, .75);
            text-align: center;
            white-space: nowrap;
            -webkit-overflow-scrolling: touch;
        }

        .nav-underline .nav-link {
            padding-top: .75rem;
            padding-bottom: .75rem;
            font-size: .875rem;
            color: #6c757d;
        }

        .nav-underline .nav-link:hover {
            color: #007bff;
        }

        .nav-underline .active {
            font-weight: 500;
            color: #343a40;
        }

        .text-white-50 {
            color: rgba(255, 255, 255, .5);
        }

        .bg-purple {
            background-color: #6f42c1;
        }

        .lh-100 {
            line-height: 1;
        }

        .lh-125 {
            line-height: 1.25;
        }

        .lh-150 {
            line-height: 1.5;
        }

        .countertextsize {
            font-size: 30px;
        }

  footer{background-color: #eee; padding: 25px;}
       ul, li{list-style-type: none;}
       .list{margin-top: 15px;}    

        pre {
        
            font-family: monospace;
            overflow-x: auto;
            margin: 1em 0;
        
            white-space: pre-line;
        }
    </style>

</head>

<body class="bg-light">

    <nav class="navbar navbar-expand-lg fixed-top navbar-dark bg-dark">
        <a class="navbar-brand mr-auto mr-lg-0" href="#">Postfix Report Dashboard</a>
    </nav>



    <main role="main" class="container">

        <div class="d-flex align-items-center p-3 my-3 text-white-50 bg-purple rounded shadow-sm">
            <i class="far fa-envelope-open fa-2x fa-fw" width="48" height="48" style="margin-right: 10px;"> </i>
            <div class="lh-100">
                <h6 class="mb-0 text-white lh-100"> Server: ##ACTIVEHOSTNAME##</h6>
                <small> Report Date: ##REPORTDATE##</small>
            </div>
        </div>


        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <strong>Privacy Alert!</strong> This report is exposing user email accounts to the internet. This page
            should be made secure and protected
            <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>

        <!-- Quick Status Blocks -->
        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <h6 class="border-bottom border-gray pb-2 mb-0">Mail Server Statistics</h6>

            <div class="container">
                <div class="row">
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Received Email</strong>
                                <span class="timer count-numbers countertextsize" data-to="##ReceivedEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Delivered Mail</strong>
                                <span class="timer count-numbers countertextsize" data-to="##DeliveredEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Forwarded Mail</strong>
                                <span class="timer count-numbers countertextsize" data-to="##ForwardedEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                </div>
            </div>


            <div class="container">
                <div class="row">
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Deferred
                                    ##DeferredEmailDeferralsCount##</strong>
                                <span class="timer count-numbers countertextsize" data-to="##DeferredEmailCount##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-danger" style="font-size: 15px;">Bounced Mail</strong>
                                <span class="timer count-numbers countertextsize" data-to="##BouncedEmail##" data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Rejected Mail
                                    ##RejectedEmailPercentage##</strong>
                                <span class="timer count-numbers countertextsize" data-to="##RejectedEmailCount##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="container">
                <div class="row">
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Rejected Warning
                                    ##RejectedEmailPercentage##</strong>
                                <span class="timer count-numbers countertextsize" data-to="##RejectedWarningsEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Held Mail</strong>
                                <span class="timer count-numbers countertextsize" data-to="##HeldEmail##" data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Discarded Mail
                                    ##DiscardedEmailPercentage##</strong>
                                <span class="timer count-numbers countertextsize" data-to="##DiscardedEmailCount##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                </div>
            </div>


            <div class="container">
                <div class="row">
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Bytes Received</strong>
                                <span class="timer count-numbers countertextsize" data-to="##BytesReceivedEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Bytes Delivered</strong>
                                <span class="timer count-numbers countertextsize" data-to="##BytesDeliveredEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Mail Senders</strong>
                                <span class="timer count-numbers countertextsize" data-to="##SendersEmail##" data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                </div>
            </div>


            <div class="container">
                <div class="row">
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Sending Hosts/Domains</strong>
                                <span class="timer count-numbers countertextsize" data-to="##SendingHostsDomainsEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Mail Recipients</strong>
                                <span class="timer count-numbers countertextsize" data-to="##RecipientsEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="media text-muted pt-3">
                            <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-white">
                                <strong class="d-block text-gray-dark" style="font-size: 15px;">Recipient Hosts/Domains</strong>
                                <span class="timer count-numbers countertextsize" data-to="##RecipientHostsDomainsEmail##"
                                    data-speed="1500"></span>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>




        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <h6 class="border-bottom border-gray pb-2 mb-0">Graphs</h6>

            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div id="PerDayTrafficSummaryTableGraph" style="width: auto; height: 400px; "></div>
                    </div>
                </div>
            </div>

            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div id="PerHourTrafficDailyAverageTableGraph" style="width: auto; height: 400px;"></div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#PerDayTrafficSummary" role="button" aria-expanded="false" aria-controls="PerDayTrafficSummary">
                <h6 class="border-bottom border-gray pb-2 mb-0">Per-Day Traffic Summary</h6>
            </a>
            <div class="container collapse" id="PerDayTrafficSummary">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive" id="PerDayTrafficSummaryTable">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Date</th>
                                        <th scope="col">Received</th>
                                        <th scope="col">Delivered</th>
                                        <th scope="col">Deferred</th>
                                        <th scope="col">Bounced</th>
                                        <th scope="col">Rejected</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##PerDayTrafficSummaryTable##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#PerHourTrafficDailyAverage" role="button" aria-expanded="false"
                aria-controls="PerHourTrafficDailyAverage">
                <h6 class="border-bottom border-gray pb-2 mb-0">Per-Hour Traffic Daily Average</h6>
            </a>
            <div class="container collapse" id="PerHourTrafficDailyAverage">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive" id="PerHourTrafficDailyAverageTable">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Time</th>
                                        <th scope="col">Received</th>
                                        <th scope="col">Delivered</th>
                                        <th scope="col">Deferred</th>
                                        <th scope="col">Bounced</th>
                                        <th scope="col">Rejected</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##PerHourTrafficDailyAverageTable##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#HostDomainSummaryMessagesReceived" role="button" aria-expanded="false"
                aria-controls="HostDomainSummaryMessagesReceived">
                <h6 class="border-bottom border-gray pb-2 mb-0">Host/Domain Summary: Messages Received</h6>
            </a>
            <div class="container collapse" id="HostDomainSummaryMessagesReceived">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Message Count</th>
                                        <th scope="col">Bytes</th>
                                        <th scope="col">Host/Domain</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##HostDomainSummaryMessagesReceived##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#SendersbyMessageSize" role="button" aria-expanded="false" aria-controls="SendersbyMessageSize">
                <h6 class="border-bottom border-gray pb-2 mb-0">Senders by Message Size</h6>
            </a>
            <div class="container collapse" id="SendersbyMessageSize">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Size</th>
                                        <th scope="col">Sender</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##SendersbyMessageSize##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#SendersbyMessageCount" role="button" aria-expanded="false" aria-controls="SendersbyMessageCount">
                <h6 class="border-bottom border-gray pb-2 mb-0">Senders by Message Count</h6>
            </a>
            <div class="container collapse" id="SendersbyMessageCount">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Message Count</th>
                                        <th scope="col">Sender</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##Sendersbymessagecount##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#RecipientsbyMessageCount" role="button" aria-expanded="false"
                aria-controls="RecipientsbyMessageCount">
                <h6 class="border-bottom border-gray pb-2 mb-0">Recipients by Message Count</h6>
            </a>
            <div class="container collapse" id="RecipientsbyMessageCount">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Message Count</th>
                                        <th scope="col">Recipient</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##RecipientsbyMessageCount##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#HostDomainSummaryMessageDelivery" role="button" aria-expanded="false"
                aria-controls="HostDomainSummaryMessageDelivery">
                <h6 class="border-bottom border-gray pb-2 mb-0">Host/Domain Summary: Message Delivery</h6>
            </a>
            <div class="container collapse" id="HostDomainSummaryMessageDelivery">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Sent Count</th>
                                        <th scope="col">Bytes</th>
                                        <th scope="col">Defers</th>
                                        <th scope="col">Average Daily</th>
                                        <th scope="col">Maximum Daily</th>
                                        <th scope="col">Host/Domain</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##HostDomainSummaryMessageDelivery##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#Recipientsbymessagesize" role="button" aria-expanded="false" aria-controls="Recipientsbymessagesize">
                <h6 class="border-bottom border-gray pb-2 mb-0">Recipients by message size</h6>
            </a>
            <div class="container collapse" id="Recipientsbymessagesize">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Size</th>
                                        <th scope="col">Recipient</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##Recipientsbymessagesize##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#Messageswithnosizedata" role="button" aria-expanded="false" aria-controls="Messageswithnosizedata">
                <h6 class="border-bottom border-gray pb-2 mb-0">Messages with no size data</h6>
            </a>
            <div class="container collapse" id="Messageswithnosizedata">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Queue ID</th>
                                        <th scope="col">Email Address</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##Messageswithnosizedata##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#MessageDeferralDetail" role="button" aria-expanded="false" aria-controls="MessageDeferralDetail">
                <h6 class="border-bottom border-gray pb-2 mb-0">Message Deferral Detail</h6>
            </a>
            <div class="container collapse" id="MessageDeferralDetail">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                    ##MessageDeferralDetail##
                        </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>



        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#MessageBounceDetailbyrelay" role="button" aria-expanded="false"
                aria-controls="MessageBounceDetailbyrelay">
                <h6 class="border-bottom border-gray pb-2 mb-0">Message Bounce Detail (By Relay)</h6>
            </a>
            <div class="container collapse" id="MessageBounceDetailbyrelay">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                        ##MessageBounceDetailbyrelay##
                            </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#MailWarnings" role="button" aria-expanded="false" aria-controls="MailWarnings">
                <h6 class="border-bottom border-gray pb-2 mb-0">Mail Warnings</h6>
            </a>
            <div class="container collapse" id="MailWarnings">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                            ##MailWarnings##
                                </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-toggle="collapse" href="#MailFatalErrors" role="button" aria-expanded="false" aria-controls="MailFatalErrors">
                <h6 class="border-bottom border-gray pb-2 mb-0">Mail Fatal Errors</h6>
            </a>
            <div class="container collapse" id="MailFatalErrors">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                        ##MailFatalErrors##
                                    </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>


    </main>


    <br>




    <!-- Footer -->
    <footer class="container-fluid text-center bg-lightgray">
        <div class="copyrights" style="margin-top:25px;">
            <p>&copy;
                <script>new Date().getFullYear() > 2010 && document.write(new Date().getFullYear());</script>
                <br>
                <span>Powered by <a href="https://github.com/KTamas/pflogsumm">PFLOGSUMM</a> </span>
                <br>
                <span><a href="https://github.com/RiaanPretoriusSA/PFLogSumm-HTML-GUI">PFLOGSUMM HTML UI Report</a> </span>
            </p>
        </div>
    </footer>




    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN"
        crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/js/bootstrap.min.js"></script>


    <!-- Icons -->
    <script src="https://unpkg.com/feather-icons/dist/feather.min.js"></script>
    <script>
        feather.replace()
    </script>

    <!-- Graphs -->
    <script src="https://code.highcharts.com/highcharts.js"></script>
    <script src="https://code.highcharts.com/modules/data.js"></script>
    <script src="https://code.highcharts.com/modules/exporting.js"></script>
    <script src="https://code.highcharts.com/modules/export-data.js"></script>

    <!-- Code Highlight-->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/prism.min.js"></script>


</body>

<script>

    Highcharts.chart('PerDayTrafficSummaryTableGraph', {
        data: {
            table: 'PerDayTrafficSummaryTable'
        },
        chart: {
            type: 'line'
        },
        title: {
            text: 'Per-Day Traffic Summary'
        },
        yAxis: {
            allowDecimals: false,
            title: {
                text: 'Units'
            }
        },

        plotOptions: {
            line: {
                dataLabels: {
                    enabled: true
                },
                enableMouseTracking: false
            }
        }

    });


    Highcharts.chart('PerHourTrafficDailyAverageTableGraph', {
        data: {
            table: 'PerHourTrafficDailyAverageTable'
        },
        chart: {
            type: 'line'
        },
        title: {
            text: 'Per-Hour Traffic Daily Average'
        },
        yAxis: {
            allowDecimals: false,
            title: {
                text: 'Units'
            }
        },

        plotOptions: {
            line: {
                dataLabels: {
                    enabled: true
                },
                enableMouseTracking: false
            }
        },



    });

</script>



<script>
    (function ($) {
        $.fn.countTo = function (options) {
            options = options || {};

            return $(this).each(function () {
                // set options for current element
                var settings = $.extend({}, $.fn.countTo.defaults, {
                    from: $(this).data('from'),
                    to: $(this).data('to'),
                    speed: $(this).data('speed'),
                    refreshInterval: $(this).data('refresh-interval'),
                    decimals: $(this).data('decimals')
                }, options);

                // how many times to update the value, and how much to increment the value on each update
                var loops = Math.ceil(settings.speed / settings.refreshInterval),
                    increment = (settings.to - settings.from) / loops;

                // references & variables that will change with each update
                var self = this,
                    $self = $(this),
                    loopCount = 0,
                    value = settings.from,
                    data = $self.data('countTo') || {};

                $self.data('countTo', data);

                // if an existing interval can be found, clear it first
                if (data.interval) {
                    clearInterval(data.interval);
                }
                data.interval = setInterval(updateTimer, settings.refreshInterval);

                // initialize the element with the starting value
                render(value);

                function updateTimer() {
                    value += increment;
                    loopCount++;

                    render(value);

                    if (typeof (settings.onUpdate) == 'function') {
                        settings.onUpdate.call(self, value);
                    }

                    if (loopCount >= loops) {
                        // remove the interval
                        $self.removeData('countTo');
                        clearInterval(data.interval);
                        value = settings.to;

                        if (typeof (settings.onComplete) == 'function') {
                            settings.onComplete.call(self, value);
                        }
                    }
                }

                function render(value) {
                    var formattedValue = settings.formatter.call(self, value, settings);
                    $self.html(formattedValue);
                }
            });
        };

        $.fn.countTo.defaults = {
            from: 0,               // the number the element should start at
            to: 0,                 // the number the element should end at
            speed: 1000,           // how long it should take to count between the target numbers
            refreshInterval: 100,  // how often the element should be updated
            decimals: 0,           // the number of decimal places to show
            formatter: formatter,  // handler for formatting the value before rendering
            onUpdate: null,        // callback method for every time the element is updated
            onComplete: null       // callback method for when the element finishes updating
        };

        function formatter(value, settings) {
            return value.toFixed(settings.decimals);
        }
    }(jQuery));

    jQuery(function ($) {
        // custom formatting example
        $('.count-number').data('countToOptions', {
            formatter: function (value, options) {
                return value.toFixed(options.decimals).replace(/\B(?=(?:\d{3})+(?!\d))/g, ',');
            }
        });

        // start all the timers
        $('.timer').each(count);

        function count(options) {
            var $this = $(this);
            options = $.extend({}, options || {}, $this.data('countToOptions') || {});
            $this.countTo(options);
        }
    });
</script>


</html>

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
