FROM ubuntu:16.04
MAINTAINER Shuquan Huang

RUN apt-get update && apt-get install -y --no-install-recommends \
                   ruby \
                   ruby-dev \
                   gcc \
                   make

RUN gem install bundler
 
RUN git clone https://github.com/shuquan/shuquan.github.io.git /shuquan.github.io

WORKDIR /shuquan.github.io

RUN bundle install && bundle exec jekyll build
 
CMD bundle exec jekyll serve
