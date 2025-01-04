# To run these tests, simply execute `nimble test`.

import unittest, json

import awsSES_SNS

import sns_examples

test "bounce me":

  var bounce = snsExampleContainer
  bounce["Message"] = ($snsSesExampleBounceJson).newJString()

  let (snsSuccess, snsMsg) = snsParseJson($bounce)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    check(false)

  check(snsParseEventType(snsMsg) == EventType.Bounce)

  let bounces = snsParseBounce(snsMsg)
  check(bounces.len == 1)
  check(bounces[0].messageID == "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000")
  check(bounces[0].bounceType == BounceType.Permanent)
  check(bounces[0].bounceSubType == BounceSubType.General)
  check(bounces[0].email == "recipient@example.com")
  check(bounces[0].status == "5.1.1")
  check(bounces[0].diagnosticCode == "smtp; 550 5.1.1 user unknown")


test "complaint me":

  var complaint = snsExampleContainer
  complaint["Message"] = ($snsSesExampleComplaintJson).newJString()

  let (snsSuccess, snsMsg) = snsParseJson($complaint)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    check(false)

  check(snsParseEventType(snsMsg) == EventType.Complaint)

  let complaints = snsParseComplaint(snsMsg)
  check(complaints.len == 1)
  check(complaints[0].messageID == "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000")
  check(complaints[0].email == "recipient@example.com")
  check(complaints[0].complaintFeedbackType == "abuse")
  check(complaints[0].arrivalDate == "2017-08-05T00:41:02.669Z")


test "delivery me":

  var delivery = snsExampleContainer
  delivery["Message"] = ($snsSesExampleDeliveryJson).newJString()

  let (snsSuccess, snsMsg) = snsParseJson($delivery)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    check(false)

  check(snsParseEventType(snsMsg) == EventType.Delivery)

  let deliveries = snsParseDelivery(snsMsg)
  check(deliveries.messageID == "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000")
  check(deliveries.timestamp == "2016-10-19T23:21:04.133Z")
  check(deliveries.email[0] == "recipient@example.com")
  check(deliveries.smtpResponse == "250 2.6.0 Message received")


test "open me":

  var open = snsExampleContainer
  open["Message"] = ($snsSesExampleOpenJson).newJString()

  let (snsSuccess, snsMsg) = snsParseJson($open)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    check(false)

  check(snsParseEventType(snsMsg) == EventType.Open)

  let opens = snsParseOpen(snsMsg)
  check(opens.messageID == "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000")
  check(opens.timestamp == "2017-08-09T22:00:19.652Z")
  check(opens.ipAddress == "192.0.2.1")
  check(opens.userAgent == "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_3 like Mac OS X) AppleWebKit/603.3.8 (KHTML, like Gecko) Mobile/14G60")


test "click me":

  var click = snsExampleContainer
  click["Message"] = ($snsSesExampleClickJson).newJString()

  let (snsSuccess, snsMsg) = snsParseJson($click)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    check(false)

  check(snsParseEventType(snsMsg) == EventType.Click)

  let clicks = snsParseClick(snsMsg)
  check(clicks.messageID == "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000")
  check(clicks.timestamp == "2017-08-09T23:51:25.570Z")
  check(clicks.ipAddress == "192.0.2.1")
  check(clicks.userAgent == "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36")
  check(clicks.link == "http://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-smtp.html")
