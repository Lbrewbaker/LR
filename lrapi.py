#!/usr/bin/env python
#! -*- coding: utf-8 -*-

import suds
import logging
import requests
import suds_requests
from suds.client import Client
from datetime import date, datetime
from suds.wsse import Security, UsernameToken

session = requests.Session()
session.verify = False # self-signed cert

logging.getLogger('suds.client').setLevel(logging.CRITICAL)

HOSTNAME = ''
USERNAME = ''
PASSWORD = ''
URL = 'https://' + HOSTNAME + '/LogRhythm.API/Services/AlarmServiceBasicAuth.svc?wsdl'

security = Security()
token = UsernameToken(USERNAME, PASSWORD)
security.tokens.append(token)

transport = suds_requests.RequestsTransport(session=session)
client = Client(URL, username=USERNAME, password=PASSWORD, transport=transport)
client.set_options(wsse=security)

start = str(date.today()) + "T00:00:00.000Z" # start of current day
end = str(date.today()) + "T23:59:59.00Z" # end of current day 
alarmStatus = "New" # only interested in alarms with a 'New' status
allusers='true'
maxresults=100 # return max 100 results

start = datetime.strptime(start, '%Y-%m-%dT%H:%M:%S.%fZ')
end = datetime.strptime(end, '%Y-%m-%dT%H:%M:%S.%fZ')

print client.service.GetFirstPageAlarmsByAlarmStatus(start, end, alarmStatus, allusers, 10)
