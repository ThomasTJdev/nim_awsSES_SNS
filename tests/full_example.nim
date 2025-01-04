
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
