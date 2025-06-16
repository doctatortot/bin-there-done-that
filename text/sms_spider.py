import scrapy
from scrapy.crawler import CrawlerRunner
from scrapy.utils.log import configure_logging
from crochet import setup, wait_for
from twisted.internet import defer
from pydispatch import dispatcher
from scrapy import signals

setup()  # Initialize Crochet

class SmsSpider(scrapy.Spider):
    name = "sms"

    def __init__(self, api_url=None, *args, **kwargs):
        super(SmsSpider, self).__init__(*args, **kwargs)
        self.api_url = api_url
        self.messages = []

    def start_requests(self):
        yield scrapy.Request(url=self.api_url, callback=self.parse)

    def parse(self, response):
        self.messages = response.json()
        for message in self.messages:
            yield message  # Yield each message individually

@wait_for(timeout=10.0)  # Timeout for blocking call
@defer.inlineCallbacks
def fetch_messages(api_url):
    configure_logging({'LOG_FORMAT': '%(levelname)s: %(message)s'})
    runner = CrawlerRunner()
    spider_cls = SmsSpider

    output = []

    # Signal handler to collect items
    def collect_items(item, response, spider):
        output.append(item)

    dispatcher.connect(collect_items, signal=signals.item_scraped)

    yield runner.crawl(spider_cls, api_url=api_url)
    defer.returnValue(output)

def run_fetch_messages(api_url):
    return fetch_messages(api_url)
