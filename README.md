
# AWS SES bounce and complaint handling through AWS SNS
This library is used to handle AWS SES bounce and complaint notifications through
AWS SNS. The library is able to parse the JSON message from AWS SNS and extract
the relevant information.

1. Create a configuration set with event notifications and a SNStopic.
2. Open AWS SES console and create a verified identity and assign the configuration set.
3. In SNS confirm the subscription to the topic.


# Learn more about AWS SES use of SNS
https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html
https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html


# Test emails from AWS SES for bounce and complaint
Use these to avoid sending emails to real addresses and getting blacklisted.
```
success@simulator.amazonses.com         # Successful delivery
bounce@simulator.amazonses.com          # Bounce
ooto@simulator.amazonses.com            # Automatic Response
complaint@simulator.amazonses.com       # Complaint
suppressionlist@simulator.amazonses.com # Recipient address on suppression list
```


# SMTP_SES
We cannot use the standard smtp library, https://github.com/nim-lang/smtp, to
send emails, since it does not support returning the last server reply which
contains the message ID. A PR has been sent: https://github.com/nim-lang/smtp/pull/18

To fix this import `smtp_ses` directly like `awsSES_SNS/smtp_ses` or just import
the full module `awsSES_SNS` which will import `smtp_ses` as well.

```nim
import awsSES_SNS
```

# Email formatting
Please refer to the package https://github.com/enthus1ast/nimMime for email
formatting. Attachments, reply-to, etc.


# Example
The example below uses mummy to create a simple server that listens for incoming
SNS messages from AWS SES.

The example below is available in the tests folder as well.

```nim
import
  std/[
    json,
    strutils
  ]

import mummy, mummy/routers
import mummy_utils

import awsSES_SNS

var router: Router
router.post("/api/webhooks/incoming/sns", proc(request: Request) =
  echo "Received SNS message POST"

  let (snsSuccess, snsMsg) = snsParseJson(request.body)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    resp Http400

  # Case through the different types of events
  case snsParseEventType(snsMsg)
  of SNSSubscriptionConfirmation:
    let sub = snsSubscriptionConfirmation(snsMsg)
    echo sub.message
    echo sub.subscribeURL

  of Bounce:
    let mailBounce = snsParseBounce(snsMsg)
    for mail in mailBounce:
      echo mail.email & " - " & $mail.bounceType & " - " & $mail.bounceSubType & " - " & mail.messageID

  of Complaint:
    let mailComplaint = snsParseComplaint(snsMsg)
    for mail in mailComplaint:
      echo mail.email & " - " & $mail.feedbackType & " - " & mail.messageID

  of Delivery:
    let mailDelivery = snsParseDelivery(snsMsg)
    echo $mailDelivery.email & " - " & mailDelivery.messageID

  of Open:
    let mailOpen = snsParseOpen(snsMsg)
    echo mailOpen.ipAddress & " - " & mailOpen.timestamp & " - " & mailOpen.messageID

  of Click:
    let mailClick = snsParseClick(snsMsg)
    echo mailClick.link & " - " & mailClick.timestamp & " - " & mailClick.messageID

  else:
    echo "Unknown event type"

  resp Http200
)

router.get("/", proc(request: Request) =
  echo "OK"
  resp Http200
)


let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
```