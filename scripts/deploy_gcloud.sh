#!/bin/bash

gcloud functions deploy parsePRBBAgenda \
--runtime python310 \
--trigger-http \
--entry-point main \
--allow-unauthenticated \
--source src \
--timeout=3600s \
--gen2
