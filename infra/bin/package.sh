#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

berks package --berksfile=$DIR/../Berksfile $DIR/../cookbooks.tar.gz
aws s3 cp $DIR/../cookbooks.tar.gz s3://ps-cookbooks/cookbooks.tar.gz --profile ps
