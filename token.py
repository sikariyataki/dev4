from bs4 import BeautifulSoup
import requests
import re
import json

from xml.etree.ElementTree import Element, SubElement
from xml.etree import ElementTree
from xml.dom import minidom

TARGET_URL = 'http://tfc.tv/show/details/382/tv-patrol'

def getData(url):
	r = requests.get(url)
	return r.text

def getMediaToken(url):
	html = getData(url)
	soup = BeautifulSoup(html, 'html.parser')
	srcs = soup.find_all('script', {"src":True})
	href = soup.find_all('a', {'href':True})
	data = []
	loop = 0
	for a in srcs:
		if a['src'].find('cl.js?token') <> -1:
			data.append(a['src'].split('token=')[1])
	for a in href:
		episode = re.compile('/episode/details/.+/tv-patrol-.+', re.IGNORECASE).search(a['href'])
		if episode:
			loop += 1
			if loop == 3:
				data.append(episode.group(0).split('/')[3])
	return data

def getJSON(token):
	url = 'http://tfc.tv/media/get'
	headers = {
		'mediaToken': token[0],
		'User-Agent': 'Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3',
		'X-Requested-With': 'XMLHttpRequest',
		#'Accept': 'application/json, text/javascript, */*; q=0.01',
		#'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
		#'Host': 'tfc.tv',
		#'Origin': 'http://tfc.tv',
		#'Referer': 'http://tfc.tv/',
		#'x-ms-request-id': 'zSU+e',
		#'x-ms-request-root-id': 'iBDIu'
	}
	res = requests.post(url, headers=headers, data={'id':token[1],'pv':True})
	return res.json()



token = getMediaToken(TARGET_URL)
media = getJSON(token)
print media['MediaReturnObj']['uri'].split('?')[1]