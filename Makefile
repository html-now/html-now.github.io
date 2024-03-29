SHELL:=/bin/bash
CURL=curl
WPTFYI=https://wpt.fyi/results

define HEAD
cat << EOF > $@
<!doctype html><html lang=en><meta charset=utf-8>
<title>The Web Platform: Browser technologies</title>
<link rel=stylesheet href="style.css">
<div id=main>
<h1>The Web Platform: Browser technologies</h1>
<p><button>Include single-engine specifications</button> • <b></b> <span>To re-sort, click on any heading.</span>
<table class=sortable>
<thead><tr><th><th>Specification<th><span>Repo</span><th><span>Docs</span><th><span>Tests</span><th><th><th>Engines<th>Category
<tbody>
EOF
endef
export HEAD

define TAIL
cat << EOF >> $@
</table>
<p>
<a href="https://github.com/html-now/html-now.github.io">Contribute on GitHub</a> •
<a id=lastmod href="https://github.com/html-now/html-now.github.io/blob/main/specdata.json">Changelog</a> •
<a href="https://projects.verou.me/css3patterns/#honeycomb">Honeycomb background by Paul Salentiny</a>
</div>
<script src="script.js"></script>
EOF
endef
export TAIL

getDaysBeforeToday=bash -c '\
  date --date="" > /dev/null 2>&1 || hasGnuDate=$$?; \
  if [ "$$hasGnuDate" != 1 ]; then \
    days=$$((($$(date -u +"%s") - $$(date -u --date="$$1" +"%s"))/86400)); \
  else \
    days=$$((($$(date -u +"%s") - $$(date -u -jf "%a, %d %b %Y %H:%M:%S GMT" "$$1" +"%s"))/86400)); \
  fi; \
  echo "$$days"' getDaysBeforeToday
ifneq (,$(filter n,$(MAKEFLAGS)))
getDaysBeforeToday=: getDaysBeforeToday
endif

getDaysBeforeTodayFromTimestamp=bash -c '\
  date --date="" > /dev/null 2>&1 || hasGnuDate=$$?; \
  if [ "$$hasGnuDate" != 1 ]; then \
    days=$$((($$(date -u +"%s") - $$1)/86400)); \
  else \
    days=$$((($$(date -u +"%s") - $$1)/86400)); \
  fi; \
  echo "$$days"' getDaysBeforeTodayFromTimestamp
ifneq (,$(filter n,$(MAKEFLAGS)))
getDaysBeforeTodayFromTimestamp=: getDaysBeforeTodayFromTimestamp
endif

getDaysBeforeTodayISO8601=bash -c '\
  date --date="" > /dev/null 2>&1 || hasGnuDate=$$?; \
  if [ "$$hasGnuDate" != 1 ]; then \
    days=$$((($$(date -u +"%s") - $$(date -u --date="$$1" +"%s"))/86400)); \
  else \
    days=$$((($$(date -u +"%s") - $$(date -u -jf "%Y-%m-%dT%H:%M:%SZ" "$$1" +"%s"))/86400)); \
  fi; \
  echo "$$days"' getDaysBeforeTodayISO8601
ifneq (,$(filter n,$(MAKEFLAGS)))
getDaysBeforeTodayISO8601=: getDaysBeforeTodayISO8601
endif
all: index.html

css-timestamps.json:
	$(CURL) -fsSL "https://w3c.github.io/csswg-drafts/timestamps.json" > css-timestamps.json

index.html: specdata.json css-timestamps.json
	eval "$$HEAD"
	eval "$$FUNCTIONS"
	printf "{" > lastupdated.json
	jq 'sort_by(.spec_name | ascii_downcase)' $< > $<.tmp; \
	$(CURL) -fsSL "https://w3c.github.io/mdn-spec-links/SPECMAP.json" > SPECMAP.json; \
	for specURL in $$(jq -r ".[].spec_url" $<.tmp); do \
		let "count++"; \
		title=""; \
		inWebKit="no"; \
		inGecko="no"; \
		inBlink="no"; \
		lastUpdated=""; \
		lastUpdatedDaysAgo=""; \
		lastUpdatedClass="red"; \
		testsImage=images/WPT.png; \
		specName=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").spec_name" $<.tmp); \
		echo; \
		printf "$$specName\n"; \
		echo $(CURL) -fsSL -I $$specURL; \
		if [ $$specURL = "https://github.com/tc39/proposal-regexp-legacy-features/" ]; then \
			response=$$($(CURL) -fsSL "https://api.github.com/repos/tc39/proposal-regexp-legacy-features/commits?path=README.md&page=1&per_page=1"); \
			lastUpdated=$$(echo $$response | jq -r '.[0].commit.committer.date'); \
			lastUpdatedDaysAgo=$$(${getDaysBeforeTodayISO8601} "$$lastUpdated"); \
		else \
			headers=$$($(CURL) -fsSL -I $$specURL); \
			lastUpdated=$$(echo "$$headers" | grep -i 'last-revised' | cut -d ":" -f2- | xargs | tr -d "\r\n"); \
			if [[ -z "$$lastUpdated" ]]; then \
				lastUpdated=$$(echo "$$headers" | grep -i 'last-modified' | cut -d ":" -f2- | xargs | tr -d "\r\n"); \
			fi; \
			if [[ -n "$$lastUpdated" ]]; then \
				lastUpdatedDaysAgo=$$(${getDaysBeforeToday} "$$lastUpdated"); \
			else \
				lastUpdatedDaysAgo="null"; \
			fi; \
		fi; \
		if [[ $$specURL == "https://drafts.csswg.org"* ]]; then \
			shortName=$${specURL:25}; \
			shortName=$${shortName/%?/}; \
			lastUpdatedTimestamp=$$(jq -r ".[\"$$shortName\"]" css-timestamps.json); \
			lastUpdatedDaysAgo=$$(${getDaysBeforeTodayFromTimestamp} "$$lastUpdatedTimestamp"); \
		fi; \
		if [[ $$count != 1 ]]; then \
			printf "," >> lastupdated.json; \
		fi; \
		printf "\n  \"%s\": %s" $$specURL $$lastUpdatedDaysAgo >> lastupdated.json; \
		mdnURL=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").mdn_url" $<.tmp); \
		repoURL=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").repo_url" $<.tmp); \
		caniuseURL=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").caniuse_url" $<.tmp); \
		testsURL=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").tests_url" $<.tmp); \
		enginesCount=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").engines | length" $<.tmp); \
		enginesArray=($$(jq -c ".[] | select(.spec_url==\"$$specURL\").engines[]" $<.tmp | tr -d '"')); \
		if [[ " $${enginesArray[*]} " =~ " webkit " ]]; then \
			inWebKit="yes"; \
		fi; \
		if [[ " $${enginesArray[*]} " =~ " gecko " ]]; then \
			inGecko="yes"; \
		fi; \
		if [[ " $${enginesArray[*]} " =~ " blink " ]]; then \
			inBlink="yes"; \
		fi; \
		specCategory=$$(jq -r ".[] | select(.spec_url==\"$$specURL\").spec_category" $<.tmp); \
		specClass=$$(printf "$$specCategory" | tr -cd '[:alnum:]'); \
		if [[ $$specURL == *"whatwg.org"* ]]; then \
			image="images/WHATWG.png"; \
			orgLink="https://spec.whatwg.org/"; \
		elif [[ $$specURL == *"webrtc"* ]]; then \
			image="images/WebRTC.png"; \
			orgLink="https://www.w3.org/groups/wg/webrtc/publications"; \
		elif [[ $$specURL == *"httpwg.org"* ]]; then \
			image="images/HTTPWG.png"; \
			testsImage=images/HTTPWG.png; \
			orgLink="https://httpwg.org/specs/"; \
		elif [[ $$specURL == *"www.rfc-editor.org"* ]]; then \
			image="images/IETF.png"; \
			orgLink="https://www.rfc-editor.org/"; \
		elif [[ $$specURL == *"datatracker.ietf.org"* ]]; then \
			image="images/IETF.png"; \
			orgLink="https://www.rfc-editor.org/"; \
		elif [[ $$specURL == *"tc39"* ]]; then \
			image="images/TC39.png"; \
			testsImage=images/Test262.png; \
			orgLink="https://tc39.es/"; \
		elif [[ $$specURL == *"gpuweb"* ]]; then \
			image="images/WebGPU.png"; \
			orgLink="http://webgpu.io/"; \
		elif [[ $$specURL == *"khronos.org"* ]]; then \
			image="images/Khronos.png"; \
			orgLink="https://registry.khronos.org/webgl/"; \
		elif [[ $$specURL == *"sourcemaps.info"* ]]; then \
			image="images/SourceMaps.png"; \
			orgLink="https://sourcemaps.info/spec.html"; \
		elif [[ $$specURL == *"immersive-web.github.io"* ]]; then \
			image="images/WebXR.png"; \
			orgLink="https://immersive-web.github.io/"; \
		elif [[ $$specURL == *"wicg.github.io"* ]]; then \
			image="images/WICG.png"; \
			orgLink="https://wicg.io/"; \
		elif [[ $$specURL == *"drafts.csswg.org"* ]]; then \
			image="images/CSSWG.png"; \
			orgLink="https://drafts.csswg.org/"; \
		elif [[ $$specURL == *"drafts.fxtf.org"* ]]; then \
			image="images/CSSWG.png"; \
			orgLink="https://drafts.fxtf.org/"; \
		elif [[ $$specURL == *"drafts.css-houdini.org"* ]]; then \
			image="images/CSSWG.png"; \
			orgLink="https://drafts.css-houdini.org/"; \
		elif [[ $$specURL == *"svgwg.org"* ]]; then \
			image="images/SVGWG.png"; \
			orgLink="https://svgwg.org/"; \
		elif [[ $$specURL == *"privacycg.github.io"* ]]; then \
			image="images/W3C.png"; \
			orgLink="https://privacycg.github.io/charter.html#work-items"; \
		elif [[ $$specURL == *"webassembly.github.io"* ]]; then \
			image="images/WebAssembly.png"; \
			orgLink="https://webassembly.org/specs/"; \
		elif [[ $$specURL == *"webaudio.github.io"* ]]; then \
			image="images/W3C.png"; \
			orgLink="https://www.w3.org/groups/wg/audio/publications"; \
		elif [[ $$specURL == *"webbluetoothcg.github.io"* ]]; then \
			image="images/W3C.png"; \
			orgLink="https://github.com/WebBluetoothCG/web-bluetooth#specification"; \
		elif [[ $$specURL == *"w3c.github.io"* ]]; then \
			image="images/W3C.png"; \
			orgLink="https://www.w3.org/TR/"; \
		elif [[ $$specURL == *"www.w3.org"* ]]; then \
			image="images/W3C.png"; \
			orgLink="https://www.w3.org/TR/"; \
		fi; \
		featureFilename=$$(jq -r .[\"$$specURL\"] SPECMAP.json); \
		$(CURL) -fsSL "https://w3c.github.io/mdn-spec-links/$$featureFilename" > $$featureFilename; \
		count=$$(jq length $$featureFilename); \
		$(RM) $$featureFilename; \
		if [ $$specURL = "https://w3c.github.io/aria/" ]; then \
			count=$$((count + $$($(CURL) -fsSL https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/index.json \
				| jq .doc.sidebarHTML | grep -E -o '/en-US/[-a-zA-Z/_]+' | tail -n +2 | wc -l))); \
		fi; \
		printf "<tr class=\"$$specClass\">" >> $@; \
		printf "<td><a href=\"$$orgLink\" title=\"$$orgLink\"><img src=\"$$image\" alt=\"$${image%.*}\"><span>$$image</span></a>" >> $@; \
		printf "<td><em><a href=\"$$specURL\">$$specName</a></em>" >> $@; \
		printf "<td>" >> $@; \
		printf "<div>" >> $@; \
		days="days"; \
		if [[ $$lastUpdatedDaysAgo -eq 1 ]]; then \
			days="day"; \
		fi; \
		if [[ $$enginesCount -gt 2 ]]; then \
			lastUpdatedClass="normal"; \
		fi; \
		if [[ $$lastUpdatedDaysAgo -lt 100 ]]; then \
			lastUpdatedClass="green"; \
		fi; \
		if [[ -n "$$lastUpdatedDaysAgo" && "$$lastUpdatedDaysAgo" != "null" ]]; then \
			title="(last updated $$lastUpdatedDaysAgo $$days ago)"; \
		fi; \
		if [[ -n "$$repoURL" && "$$repoURL" != null ]]; then \
			printf "<a href=\"$$repoURL\" title=\"$$repoURL $$title\"><img src=\"images/GitHub.png\" alt=\"GitHub\"></a>" >> $@; \
		else \
			printf "<img class=\"no\" src=\"images/GitHub.png\" alt=\"No GitHub repo\"></a>" >> $@; \
		fi; \
		if [[ -n "$$lastUpdatedDaysAgo" && "$$lastUpdatedDaysAgo" != "null" ]]; then \
			if [[ -n "$$repoURL" && "$$repoURL" != null ]]; then \
				printf "<em class=\"$$lastUpdatedClass\"><a href=\"$$repoURL\" title=\"$$repoURL $$title\">$$lastUpdatedDaysAgo</a></em>" >> $@; \
			else \
				printf "<em class=\"$$lastUpdatedClass\">$$lastUpdatedDaysAgo</em>" >> $@; \
			fi; \
		else \
			printf "<span>no date available</span>" >> $@; \
		fi; \
		printf "</div>" >> $@; \
		printf "<td>" >> $@; \
		printf "<div>" >> $@; \
		if [[ -n "$$mdnURL" && "$$mdnURL" != null ]]; then \
			printf " <a href=\"$$mdnURL\" title=\"$$mdnURL\"><img src=\"images/MDN.png\" alt="MDN"></a>" >> $@; \
		else \
			printf " <img src=\"images/MDN.png\" alt="MDN" title=\"MDN has no overview article for this specification.\">" >> $@; \
		fi; \
		articles="articles"; \
		if [[ $$count -eq 1 ]]; then \
			articles="article"; \
		fi; \
		title="MDN has $$count $$articles related to this specification."; \
		printf "<em><a href=\"https://w3c.github.io/mdn-spec-links/mdn.html?url=$$specURL&overview=$$mdnURL\" title=\"$$title\">$$count</a></em>" >> $@; \
		printf "</div>" >> $@; \
		printf "<td>" >> $@; \
		if [[ -n "$$testsURL" && "$$testsURL" != null ]]; then \
			printf "<a href=\"$$testsURL\" title=\"$$testsURL\">" >> $@; \
			printf "<img src=\"$$testsImage\" alt=\"$${testsImage%.*}\"></a>" >> $@; \
			printf "<span>$$testsURL</span>" >> $@; \
		fi; \
		printf "<td>" >> $@; \
		if [[ $$enginesCount -eq 0 ]]; then \
			shortEnginesStatement="no conforming implementations"; \
			enginesStatement="This specification has $$shortEnginesStatement."; \
			statusIndicatorElement="<s title=\"$$enginesStatement\">⚠</s> "; \
		elif [[ $$enginesCount -eq 1 ]]; then \
			shortEnginesStatement="$${enginesArray[0]} only"; \
			enginesStatement="This specification is implemented in $$shortEnginesStatement."; \
			statusIndicatorElement="<s title=\"$$enginesStatement\">⚠</s> "; \
		elif [[ $$enginesCount -eq 2 ]]; then \
			shortEnginesStatement="$${enginesArray[0]} and $${enginesArray[1]} only"; \
			enginesStatement="This specification is implemented in $$shortEnginesStatement."; \
			statusIndicatorElement="<b title=\"$$enginesStatement\">✔</b><span>two</span>"; \
		elif [[ $$enginesCount -gt 2 ]]; then \
			shortEnginesStatement="in all engines"; \
			enginesStatement="This specification is implemented in $$shortEnginesStatement."; \
			statusIndicatorElement="<i title=\"$$enginesStatement\">✔</i><span>all</span>"; \
		fi; \
		if [[ -n "$$caniuseURL" && "$$caniuseURL" != null ]]; then \
			printf "<a href=\"$$caniuseURL\" title=\"$$caniuseURL ($$shortEnginesStatement)\">" >> $@; \
			printf "<img src=\"images/CanIUse.png\" alt=\"CanIUse\"></a>" >> $@; \
			printf "<span>caniuse</span>" >> $@; \
		fi; \
		printf "<td>" >> $@; \
		printf "<a href=\"https://w3c.github.io/mdn-spec-links/less-than-2.html?spec=$${featureFilename%.*}\">" >> $@; \
		printf "$$statusIndicatorElement" >> $@; \
		printf "</a>" >> $@; \
		printf "<td>" >> $@; \
		printf " <a href=\"https://mozilla.github.io/standards-positions/\" title=\"https://mozilla.github.io/standards-positions/\"><img class=\"$$inGecko\" src=\"images/Gecko.png\" alt=\"Gecko: $$inGecko\"></a>" >> $@; \
		printf " <a href=\"https://webkit.org/status/\" title=\"https://webkit.org/status/\"><img class=\"$$inWebKit\" src=\"images/WebKit.png\" alt=\"WebKit: $$inWebKit\"></a>" >> $@; \
		printf " <a href=\"https://chromestatus.com/features\" title=\"https://chromestatus.com/features\"><img class=\"$$inBlink\" src=\"images/Blink.png\" alt=\"Blink: $$inBlink\"></a>" >> $@; \
		printf "<span>$$inGecko $$inWebKit $$inBlink</span>" >> $@; \
		printf "<td><u class="$$specClass" title=\"Click to toggle between showing &#x201c;$$specCategory&#x201d; specs only, or showing all specs.\">$$specCategory</u>\n" >> $@; \
	done
	eval "$$TAIL"
	printf "\n}\n" >> lastupdated.json
	jq --sort-keys . lastupdated.json > lastupdated.json.tmp \
		&& mv lastupdated.json.tmp lastupdated.json
	$(RM) SPECMAP.json
	$(RM) $<.tmp

clean:
	$(RM) css-timestamps.json
	$(RM) index.html
