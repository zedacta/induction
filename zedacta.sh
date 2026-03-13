#!/bin/bash


SERVER_IP=${Z_SERVER_IP}
API_KEY=${Z_BETA_KEY}

# --- STEP 0: THE SOVEREIGN ARGUMENT LOOP ---
CUSTOM_BLUEPRINT_PATH=""
REMAINING_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) CUSTOM_BLUEPRINT_PATH="$2"; shift 2 ;; # Refactored to -b for Blueprint
    *) REMAINING_ARGS+=("$1"); shift 1 ;;
  esac
done

set -- "${REMAINING_ARGS[@]}"

CSV_FILE=$1
COL_NAME=$2
LIMIT=${3:-50}
# Positional fallback if -b wasn't used
CUSTOM_BLUEPRINT_PATH=${CUSTOM_BLUEPRINT_PATH:-$4}

if ! command -v python3 &> /dev/null; then
    echo "ERROR: PYTHON 3 NOT DETECTED. THE OBSIDIAN REACTOR REQUIRES A PYTHON CORE FOR INDUCTION."
    exit 1
fi

if [ -z "$SERVER_IP" ] || [ -z "$API_KEY" ]; then
    echo "ERROR: MISSING CREDENTIALS. SET Z_SERVER_IP AND Z_BETA_KEY TO IGNITE."
    exit 1
fi

# --- STEP 0: KINETIC GUARDS ---
if [ -z "$2" ]; then 
    echo "Usage: Z_SERVER_IP=x Z_BETA_KEY=y ./zedacta.sh <csv_file> <column_name> [optional_limit] [optional_blueprint_path]"
    exit 1
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 1 ] || [ "$LIMIT" -gt 50 ]; then
    echo "ERROR: INVALID BATCH SIZE ($LIMIT). DEMO LIMIT: 1-50."
    exit 1
fi

# Pre-flight Ore Validation (Checking the CSV headers)
COL_CHECK=$(python3 -c "import csv; f=open('$CSV_FILE', 'r'); h=next(csv.reader(f)); print('VALID' if '$COL_NAME' in h else 'INVALID:'+str(h)); f.close()")
if [[ "$COL_CHECK" == INVALID* ]]; then
    echo "ERROR: Column '$COL_NAME' not found in $CSV_FILE. Extraction aborted."; exit 1
fi


echo "[1/5] SELECTING ZEDACTA BLUEPRINT..."

if [ -n "$CUSTOM_BLUEPRINT_PATH" ]; then
    # AUTOMATIC BYPASS: Direct Architecture Intake
    CLASS=$(python3 -c "import json; b=json.load(open('$CUSTOM_BLUEPRINT_PATH')).get('blueprint', {}); print(b.get('class', 'CUSTOM INDUSTRIAL BLUEPRINT'))")
    JUNCTIONS=$(python3 -c "import json; b=json.load(open('$CUSTOM_BLUEPRINT_PATH')).get('blueprint', {}); print(json.dumps(b.get('junctions', [])))")
else
    echo "SELECT YOUR ZEDACTA BLUEPRINT:"
    echo "1) COMPLIANCE AUDIT            (HYBRID: Structural + Semantic)"
    echo "2) PRIVACY GUARD PROTOCOL      (PHYSICAL: Structural + Structural)"
    echo "3) DEPARTMENTAL REFINERY       (SEMANTIC: Semantic + Semantic)"
    echo "4) CUSTOM INDUSTRIAL BLUEPRINT (FILE: Your Blueprint.json)"
    read -p "Choice [1-4]: " BLUEPRINT_CHOICE
    
    case $BLUEPRINT_CHOICE in
      1) CLASS="COMMUNICATION_AUDIT"
         # THE HYBRID: Combines a Physical Pattern with Forensic Reasoning
         JUNCTIONS='[
           {"field":"correspondent_address","description":"REFINERY LOGIC: Extract the email of the person Phillip Allen is communicating with. If he is the Sender, extract the Recipient. If he is the Recipient, extract the Sender.","pattern":"CLEAN_PII"},
           {"field":"severity_level","values":["Level-1","Level-2","Level-3"]}
         ]' ;;
      2) CLASS="PRIVACY_GUARD_PROTOCOL"
         # THE PHYSICAL: Dual-Vector Hardware Enforcement (Regex Only)
         JUNCTIONS='[
           {"field":"identity_scrub","description":"Extract the primary non-Enron email address for PII redaction.","pattern":"CLEAN_PII"},
           {"field":"message_origin_date","description":"Extract the primary message date.","pattern":"STANDARD_DATE"}
         ]' ;;
      3) CLASS="DEPARTMENTAL_REFINERY"
         # THE SEMANTIC: Dual-Vector Reasoning (Enums Only)
         JUNCTIONS='[
           {"field":"communication_intent","description":"REFINERY LOGIC: Determine the primary intent. Is this a casual '\''Greeting'\'', a '\''Schedule'\'' request, a '\''Trading'\'' directive, or '\''Legal'\'' posturing?","values":["Greeting", "Schedule", "Trading", "Personal", "Legal"]},
           {"field":"risk_appraisal","description":"FORENSIC AUDIT: Appraise the risk of this communication. Level-1 is routine. Level-3 is high-risk/toxic.","values":["Level-1", "Level-2", "Level-3"]}
         ]' ;;
      4) read -p "Enter path to <blueprint.json>: " B_PATH
         [[ ! -f "$B_PATH" ]] && echo "ERROR: BLUEPRINT NOT FOUND" && exit 1
         CLASS=$(python3 -c "import json; b=json.load(open('$B_PATH')).get('blueprint', {}); print(b.get('class', 'CUSTOM INDUSTRIAL BLUEPRINT'))")
         JUNCTIONS=$(python3 -c "import json; b=json.load(open('$B_PATH')).get('blueprint', {}); print(json.dumps(b.get('junctions', [])))") ;;
      *) echo "FRACTURE: Invalid choice."; exit 1 ;;
    esac
fi

# --- STEP 2: DIRECT INJECTION ---
echo -n "[2/5] CASTING & IGNITING REACTOR: ["

# THE LAMINAR BRIDGE: Exporting ensures the Python sub-process doesn't see 'None'
export Z_JUNCTIONS_PASS="$JUNCTIONS"
RESPONSE_FILE=$(mktemp)

# We use double quotes for the python -c to allow Bash variable expansion for $CSV_FILE and $COL_NAME
python3 -c "import csv, json, sys, os; \
csv.field_size_limit(10 * 1024 * 1024); \
r=csv.DictReader(open('$CSV_FILE', 'r')); \
d=[{'id': i+1, '$COL_NAME': row.get('$COL_NAME', '').replace('\n', ' ')} for i, row in enumerate(r) if i < $LIMIT]; \
print(json.dumps({ \
    'blueprint': { \
        'class': '$CLASS', \
        'junctions': json.loads(os.getenv('Z_JUNCTIONS_PASS', '[]')) \
    }, \
    'data': d \
}))" | \
curl -si -X POST "http://$SERVER_IP:8000/v1/synthesize" \
-H "Content-Type: application/json" \
-H "X-API-KEY: $API_KEY" \
--data-binary @- > "$RESPONSE_FILE" 2>&1 &

# THE KINETIC MASK: We animate the rail while the PID is alive
PID=$!
while kill -0 $PID 2>/dev/null; do
    echo -n "#"
    sleep 0.2
done

# Fill the rest of the rail once the upload is complete
echo -n "####################"
echo "] COMPLETE"

RESPONSE=$(cat "$RESPONSE_FILE")
rm "$RESPONSE_FILE"


# 2. THE LICENSE PLATE EXTRACTION
BATCH_ID=$(echo "$RESPONSE" | grep -i 'X-Zedacta-Batch-ID' | awk '{print $2}' | tr -d '\r')

# 3. THE GAVEL STRIKE: Precision Extraction of the Error Message
if [[ -z "$BATCH_ID" ]]; then 
    echo "--------------------------------------------------------"
    echo "FRACTURE: THE REACTOR REFUSED THE BLUEPRINT (422). Invalid Credentials OR Blueprint Architecture."
    
    # THE BLUEPRINT REPAIR: Targeted error extraction from the Pydantic response
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"msg":"[^"]*"' | head -n 1 | cut -d'"' -f4)
    
    if [[ -n "$ERROR_MSG" ]]; then
        echo "VERDICT: $ERROR_MSG"
    else
        # Fallback: Capture the raw structural failure
        echo "$RESPONSE" | grep -o '{"detail":.*}' | cut -c1-200
    fi
    echo "--------------------------------------------------------"
    exit 1 
fi

# --- STEP 3: MONITORING PULSE ---
echo "[3/5] MONITORING SYNTHESIS JUNCTION: $BATCH_ID"

# We initialize a 'Kinetic Flicker' for the ignition state
COUNTER=0
while true; do
    PULSE=$(curl -s "http://$SERVER_IP:8000/refinery/pulse/$BATCH_ID")
    
    # If the Reactor hasn't stabilized the Junction yet (404 or Quiescent)
    STATUS=$(echo "$PULSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status','Quiescent'))")

    if [[ "$STATUS" == "Quiescent" ]]; then
        DOTS=$(printf "%$(( (COUNTER % 3) + 1 ))s" | tr " " ".")
        # Refactored to "STABILIZING JUNCTION" to match the Day 2 narrative
        printf "\033[H\033[JSTABILIZING SYNTHESIS JUNCTION%s\n" "$DOTS"
        ((COUNTER++))
        sleep 0.3
        continue
    fi

# THE LAMINAR PULSE: High-Velocity Telemetry from the Foundry
OUTPUT=$(cat <<EOF


ZEDACTA REACTOR PULSE
--------------------------------------------------------
$(echo "$PULSE" | python3 -m json.tool)
EOF
    )
    printf "\033[H\033[J%s\n" "$OUTPUT"

    if [[ "$STATUS" == "COMPLETED" ]]; then
        sleep 0.8 # 
        echo -e "\n"
        break
    fi
    sleep 0.1
done


# --- STEP 4: SECURING GAVEL-VERIFIED CONTRACT ---
echo -n "[4/5] SECURING GAVEL-VERIFIED CONTRACT: ["


RAW_FILENAME="data/chute/$BATCH_ID.json"
mkdir -p "data/chute"


curl -s -f -o "$RAW_FILENAME" "http://$SERVER_IP:8000/v1/results/$BATCH_ID"

# The Loading "Stutter": Makes it look like it's actually verifying bytes
for i in {1..14}; do 
    echo -n "#"
    [[ $i -eq 10 ]]
    sleep 0.04 
done
echo "]"

sleep 1.2 # THE COOLING GAP: Dramatic transition to the final step

# --- STEP 5: GENERATING THE INDUSTRIAL CoA ---
echo -n "[5/5] GENERATING CERTIFICATE OF ANALYSIS: ["
CERT_FILENAME="data/chute/$BATCH_ID.pdf"
mkdir -p "data/chute"

# THE KINETIC SNAP: 15 hashes at 0.04s to match Step 4 exactly
for i in {1..12}; do 
    echo -n "#"
    sleep 0.04 
done

curl -s -f -o "$CERT_FILENAME" "http://$SERVER_IP:8000/v1/render/pdf/$BATCH_ID" > /dev/null 2>&1

echo "]"

# --- THE FINAL QUIESCENCE ---
echo "--------------------------------------------------------"
echo "REFINERY STATUS: QUIESCENT | BATCH: $BATCH_ID COMPLETE"
echo "--------------------------------------------------------"
echo "MASTER LEDGER: data/chute/$BATCH_ID.json"
echo "AUDIT CERTIFICATE: $CERT_FILENAME"
echo "--------------------------------------------------------"

# --- THE SOVEREIGN CHOICE ---
# We check if the file exists and has size (-s) before prompting
# This will NOT work on Remote - SSH
if [[ -s "$CERT_FILENAME" ]]; then
    echo -n "VIEW AUDIT CERTIFICATE NOW? (y/n): "
    read -n 1 -r
    echo "" # Move to new line
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        case "$OSTYPE" in
          darwin*)  open "$CERT_FILENAME" ;; 
          linux*)   xdg-open "$CERT_FILENAME" >/dev/null 2>&1 & ;;
        esac
    fi
fi
