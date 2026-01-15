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
  check(bounces[0].parsingSucceeded == true)


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
  check(complaints[0].complaintFeedbackType == ComplaintFeedbackType.abuse)
  check(complaints[0].arrivalDate == "2017-08-05T00:41:02.669Z")
  check(complaints[0].parsingSucceeded == true)


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
  check(deliveries.parsingSucceeded == true)


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
  check(opens.parsingSucceeded == true)


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
  check(clicks.parsingSucceeded == true)


test "parsing failures with wrong json keys":

  # Test with invalid bounce JSON - missing required keys
  var invalidBounce = snsExampleContainer
  invalidBounce["Message"] = ($(%* {
    "eventType": "Bounce",
    "bounce": {
      "wrongKey": "wrongValue"
      # Missing bouncedRecipients, bounceType, etc.
    },
    "mail": {
      "wrongMessageIdKey": "some-id"
      # Missing messageId
    }
  })).newJString()

  let (snsSuccess1, snsMsg1) = snsParseJson($invalidBounce)
  check(snsSuccess1 == true)  # JSON parsing succeeds, but content is invalid

  let bounces = snsParseBounce(snsMsg1)
  check(bounces.len == 0)  # Should return empty sequence on failure


  # Test with invalid delivery JSON - wrong key names
  var invalidDelivery = snsExampleContainer
  invalidDelivery["Message"] = ($(%* {
    "eventType": "Delivery",
    "delivery": {
      "wrongTimestampKey": "2016-10-19T23:21:04.133Z",
      "wrongRecipientsKey": ["recipient@example.com"],
      "wrongSmtpResponseKey": "250 2.6.0 Message received"
      # All keys are wrong
    },
    "mail": {
      "wrongMessageIdKey": "some-id"
    }
  })).newJString()

  let (snsSuccess2, snsMsg2) = snsParseJson($invalidDelivery)
  check(snsSuccess2 == true)

  let deliveries = snsParseDelivery(snsMsg2)
  check(deliveries.parsingSucceeded == false)
  check(deliveries.messageID == "")
  check(deliveries.timestamp == "")
  check(deliveries.email.len == 0)
  check(deliveries.smtpResponse == "")


  # Test with invalid open JSON - missing required keys
  var invalidOpen = snsExampleContainer
  invalidOpen["Message"] = ($(%* {
    "eventType": "Open",
    "open": {
      # Missing all required fields
    },
    "mail": {
      "wrongMessageIdKey": "some-id"
    }
  })).newJString()

  let (snsSuccess3, snsMsg3) = snsParseJson($invalidOpen)
  check(snsSuccess3 == true)

  let opens = snsParseOpen(snsMsg3)
  check(opens.parsingSucceeded == false)
  check(opens.messageID == "")
  check(opens.timestamp == "")
  check(opens.ipAddress == "")
  check(opens.userAgent == "")


  # Test with invalid click JSON - wrong structure
  var invalidClick = snsExampleContainer
  invalidClick["Message"] = ($(%* {
    "eventType": "Click",
    "click": {
      "wrongIpKey": "192.0.2.1",
      "wrongLinkKey": "http://example.com",
      "wrongUserAgentKey": "Mozilla"
      # All keys are wrong
    },
    "mail": {
      "wrongMessageIdKey": "some-id"
    }
  })).newJString()

  let (snsSuccess4, snsMsg4) = snsParseJson($invalidClick)
  check(snsSuccess4 == true)

  let clicks = snsParseClick(snsMsg4)
  check(clicks.parsingSucceeded == false)
  check(clicks.messageID == "")
  check(clicks.timestamp == "")
  check(clicks.ipAddress == "")
  check(clicks.userAgent == "")
  check(clicks.link == "")


  # Test with invalid complaint JSON - missing required keys
  var invalidComplaint = snsExampleContainer
  invalidComplaint["Message"] = ($(%* {
    "eventType": "Complaint",
    "complaint": {
      "wrongRecipientsKey": [
        {
          "wrongEmailKey": "recipient@example.com"
        }
      ]
      # Missing complainedRecipients, complaintFeedbackType, arrivalDate
    },
    "mail": {
      "wrongMessageIdKey": "some-id"
    }
  })).newJString()

  let (snsSuccess5, snsMsg5) = snsParseJson($invalidComplaint)
  check(snsSuccess5 == true)

  let complaints = snsParseComplaint(snsMsg5)
  check(complaints.len == 0)  # Should return empty sequence on failure