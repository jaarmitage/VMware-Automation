# vecs-cli Expired Certificates Parse Utility
# Joshua Armitage
# joshua.armitage@broadcom.com
#
# Usage:
#   vecs-cli entry list --store TRUSTED_ROOTS --text | awk -f filter_expired.sh -- -days=30
#   Default: shows only expired certificates (days=0)
#
# Note:
#   You should save this either in an executable path or use the full path to the script
#   when calling it (e.g.: vecs-cli ... | awk -f /path/to/file/filter_expired.sh).
#   Remember to make this executable!

BEGIN {
    # Parse CLI args (after "--")
    days = 0
    for (i = 1; i < ARGC; i++) {
        if (ARGV[i] ~ /^-days=/) {
            split(ARGV[i], a, "=")
            days = a[2]
            ARGV[i] = ""   # Remove from AWK args
        }
    }

    # Get current time in epoch seconds
    "date +%s" | getline today
    close("date +%s")

    # Cutoff time: anything before this is "soon or expired"
    cutoff = today + (days * 86400)

    # Month mapping
    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", m)
    for (i=1; i<=12; i++) month[m[i]] = i
}

# Start of new certificate block
/^[[:space:]]*Alias[[:space:]]*:/ {
    if (block && notafter <= cutoff) {
        printf "%s", block
    }
    block = $0 "\n"
    notafter = 9999999999   # default far future
    next
}

# Append all lines to current block
{
    block = block $0 "\n"
}

# Match "Not After" line (flexible spacing)
/^[[:space:]]*Not[[:space:]]+After[[:space:]]*:/ {
    # Example fields: [..] Aug  6 15:26:49 2035 GMT
    monname = $(NF-4)
    day     = $(NF-3)
    time    = $(NF-2)
    year    = $(NF-1)
    split(time, t, ":")
    monnum = month[monname]
    notafter = mktime(year " " monnum " " day " " t[1] " " t[2] " " t[3])
}

# End of file — check last block
END {
    if (block) {
        if (notafter == 9999999999) {
            print "WARNING: No Not After date found for final block:\n" block > "/dev/stderr"
        } else if (notafter <= cutoff) {
            printf "%s", block
        }
    }
}