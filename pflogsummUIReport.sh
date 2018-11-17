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
LOGFILELOCATION="/var/log/maillog"

##  pflogsumm details
PFLOGSUMMOPTIONS=" --verbose_msg_detail --zero_fill "
PFLOGSUMMBIN="/usr/sbin/pflogsumm  "

##  HTML Output
HTMLOUTPUTDIR="/var/www/html/"
HTMLOUTPUT_INDEXDASHBOARD="index.html"

EOF
fi

#Load Config File
. ${PFSYSCONFDIR}/"pflogsumui.conf"


#Create the Cache Directory if it does not exist
if [ ! -d $HTMLOUTPUTDIR/data ]; then
  mkdir  $HTMLOUTPUTDIR/data;
fi


ACTIVEHOSTNAME=$(cat /proc/sys/kernel/hostname)

#Temporal Values
REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTYEAR=$(date +'%Y')
CURRENTMONTH=$(date +'%b')
CURRENTDAY=$(date +"%d")

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

cat > $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD << 'HTMLOUTPUTINDEXDASHBOARD'
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="Postfix PFLOGSUMM Dashboard Index">
    <meta name="author" content="Riaan Pretorius">
    <link rel="icon" href="http://www.postfix.org/favicon.ico">

    <title>Dashboard Template for Bootstrap</title>

    <!-- Bootstrap core CSS -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.css">


    <style>
        body {
            padding-top: 5rem;
        }

        footer {
            background-color: #eee;
            padding: 25px;
        }

        .spacer10 {
            height: 10px;
        }
    </style>

</head>

<body>

    <nav class="navbar navbar-expand-md navbar-dark bg-dark fixed-top">
        <a class="navbar-brand" href="#">Postfix PFLOGSUMM Dashboard</a>
    </nav>




    <div class="container">


        <h3 class="pb-3 mb-4 font-italic border-bottom">
            Select Report
            <dl class="row">
                <dt class="col-sm-3" style="font-size: 0.5em;">Last Update</dt>
                <dd class="col-sm-9" style="font-size: 0.5em;">##REPORTDATE##</dd>
                <dt class="col-sm-3" style="font-size: 0.5em;">Server</dt>
                <dd class="col-sm-9" style="font-size: 0.5em;">##ACTIVEHOSTNAME##</dd>

            </dl>
        </h3>


        <div class="row">

            <div class="col-sm">

                <!-- January Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">January</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##JanuaryCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#JanuaryCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="JanuaryCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush JanuaryList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- January End -->

            </div>

            <div class="col-sm">

                <!-- February Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">February</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##FebruaryCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#FebruaryCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="FebruaryCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush FebruaryList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- February End -->

            </div>

            <div class="col-sm">

                <!-- March Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">March</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##MarchCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#MarchCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="MarchCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush MarchList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- March End -->

            </div>

            <div class="col-sm">

                <!-- April Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">April</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##AprilCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#AprilCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="AprilCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush AprilList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- April End -->

            </div>


        </div>

        <br>

        <div class="row">

            <div class="col-sm">

                <!-- May Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">May</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##MayCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#MayCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="MayCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush MayList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- May End -->

            </div>

            <div class="col-sm">

                <!-- June Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">June</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##JuneCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#JuneCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="JuneCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush JuneList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- June End -->

            </div>

            <div class="col-sm">

                <!-- July Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">July</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##JulyCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#JulyCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="JulyCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush JulyList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- July End -->

            </div>

            <div class="col-sm">

                <!-- August Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">August</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##AugustCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#AugustCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="AugustCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush AugustList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- August End -->

            </div>

        </div>

        <br>

        <div class="row">

            <div class="col-sm">

                <!-- September Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">September</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##SeptemberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#SeptemberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="SeptemberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush SeptemberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- September End -->

            </div>

            <div class="col-sm">

                <!-- October Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">October</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##OctoberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#OctoberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="OctoberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush OctoberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- October End -->

            </div>

            <div class="col-sm">

                <!-- November Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">November</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##NovemberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#NovemberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="NovemberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush NovemberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- November End -->

            </div>

            <div class="col-sm">

                <!-- December Start-->
                <div class="card flex-md-row mb-4 shadow-sm h-md-250">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">December</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##DecemberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-toggle="collapse" href="#DecemberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="DecemberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush DecemberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- December End -->

            </div>

        </div>

    </div>



    <br>



    <!-- Footer -->
    <footer class="container-fluid text-center bg-lightgray">
        <div class="copyrights" style="margin-top:25px;">
            <p>&copy;
                <script>new Date().getFullYear() > 2010 && document.write(new Date().getFullYear());</script>
                <br>
                <span>Powered by <a href="https://github.com/KTamas/pflogsumm">PFLOGSUMM</a> </span>
                <br>
                <span><a href="https://github.com/RiaanPretoriusSA/PFLogSumm-HTML-GUI">PFLOGSUMM HTML UI Report</a>
                </span>
            </p>
        </div>
    </footer>
    <!-- Footer -->


    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/js/bootstrap.min.js"></script>
    <!-- Popper.JS -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.5/umd/popper.min.js"></script>

</body>


<script>
    $(document).ready(function () {
        $('.JanuaryList').load("data/jan_rpt.html?rnd=" + Math.random());
        $('.FebruaryList').load("data/feb_rpt.html?rnd=" + Math.random());
        $('.MarchList').load("data/mar_rpt.html?rnd=" + Math.random());
        $('.AprilList').load("data/apr_rpt.html?rnd=" + Math.random());
        $('.MayList').load("data/may_rpt.html?rnd=" + Math.random());
        $('.JuneList').load("data/jun_rpt.html?rnd=" + Math.random());
        $('.JulyList').load("data/jul_rpt.html?rnd=" + Math.random());
        $('.AugustList').load("data/aug_rpt.html?rnd=" + Math.random());
        $('.SeptemberList').load("data/sep_rpt.html?rnd=" + Math.random());
        $('.OctoberList').load("data/oct_rpt.html?rnd=" + Math.random());
        $('.NovemberList').load("data/nov_rpt.html?rnd=" + Math.random());
        $('.DecemberList').load("data/dec_rpt.html?rnd=" + Math.random());
    });
</script>



</body>

</html>
HTMLOUTPUTINDEXDASHBOARD




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
# Count Existing Reports - For Dashboard Display
#======================================================
JanRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Jan*.html | wc -l)
FebRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Feb*.html | wc -l)
MarRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Mar*.html | wc -l)
AprRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Apr*.html | wc -l)
MayRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-May*.html | wc -l)
JunRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Jun*.html | wc -l)
JulRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Jul*.html | wc -l)
AugRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Aug*.html | wc -l)
SepRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Sep*.html | wc -l)
OctRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Oct*.html | wc -l)
NovRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Nov*.html | wc -l)
DecRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Dec*.html | wc -l)


#======================================================
# Replace Report Totals for Report - Index
#======================================================
sed -i "s/##JanuaryCount##/$JanRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##FebruaryCount##/$FebRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##MarchCount##/$MarRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##AprilCount##/$AprRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##MayCount##/$MayRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##JuneCount##/$JunRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##JulyCount##/$JulRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##AugustCount##/$AugRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##SeptemberCount##/$SepRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##OctoberCount##/$OctRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##NovemberCount##/$NovRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##DecemberCount##/$DecRPTCount/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD

sed -i "s/##REPORTDATE##/$REPORTDATE/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##ACTIVEHOSTNAME##/$ACTIVEHOSTNAME/g" $HTMLOUTPUTDIR/$HTMLOUTPUT_INDEXDASHBOARD


#======================================================
# Clean UP
#======================================================
