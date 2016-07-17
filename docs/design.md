# Design

The design of Omnivore is based on a simple application view:

* Receive payload from arbitrary source.
* Perform actions based on payload.
* Pass payload to next destination (if any).
* Confirm message has been processed with original source.
