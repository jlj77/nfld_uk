# mkws customisations

## rss.uppxml
My copy of `mkws` pre-processes `share/rss.uppxml` to create a simple RSS feed, based off of `wdiff` output of HTML files in the current working directory. In each case, it expects the older file to have an additional .old extension.

### Dependencies
- wdiff

## pads2html.sh
Crawls the master Etherpad for our book club – at: https://pad.nfld.uk/p/bookclub_master – looking for other linked Etherpads to pull down. All of these are exported to HTML files, with any pre-existing copies moved to .old prior to the `curl`. These HTML files are styled with [Sakura](https://oxal.org/projects/sakura).

### Dependencies
- curl
- tidy (HTML tidy)
- lynx
- gawk
- Sakura

### Notes
- I run this script as a cron job every 24 hours.
- All the regex code could be rewritten to reduce the listed dependencies, of course. But it works!
