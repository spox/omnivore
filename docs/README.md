# Introduction

Omnivore is a simple framework for performing complex tasks
via small specialized actions. It follows the KISS principle
to support building complex pipelines. At the core of Omnivore's
implementation is a collection of endpoints. Each endpoint
can listen to multiple sources for new messages. When a message
is received, the endpoint processes the message through any
actions it has configured. This style of implementation makes
it simple to run as a single monolithic application, or multiple
isolated microservices all working together.
