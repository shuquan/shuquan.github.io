FROM ubuntu:14.04
MAINTAINER Shuquan Huang

RUN apt-get update && apt-get install -y --no-install-recommends \
                   gem
RUN gem install jekyll bundler

