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
    echo "ERROR: REACTOR OFFLINE. SET Z_SERVER_IP AND Z_BETA_KEY TO IGNITE."
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


# --- STEP 1: BLUEPRINT SELECTION ---
echo "[1/5] SELECTING ZEDACTA BLUEPRINT..."

if [ -n "$CUSTOM_BLUEPRINT_PATH" ]; then
    # AUTOMATIC BYPASS: Direct Architecture Intake
    CLASS=$(python3 -c "import json; b=json.load(open('$CUSTOM_BLUEPRINT_PATH')).get('blueprint', {}); print(b.get('class', 'CUSTOM INDUSTRIAL BLUEPRINT'))")
    JUNCTIONS=$(python3 -c "import json; b=json.load(open('$CUSTOM_BLUEPRINT_PATH')).get('blueprint', {}); print(json.dumps(b.get('junctions', [])))")
else
    echo "SELECT YOUR ZEDACTA BLUEPRINT:"
    echo "1) SOVEREIGN COMPLIANCE AUDIT  (HYBRID)"
    echo "2) PRIVACY GUARD PROTOCOL      (PHYSICAL)"
    echo "3) DEPARTMENTAL REFINERY       (SEMANTIC)"
    echo "4) CUSTOM INDUSTRIAL BLUEPRINT (FILE)"
    read -p "Choice [1-4]: " MOLD_CHOICE
    
    case $MOLD_CHOICE in
      1) CLASS="SOVEREIGN COMPLIANCE AUDIT"
         JUNCTIONS='[{"field":"extracted_email","type":"string","pattern":"CLEAN_PII"},{"field":"severity_danger_level","type":"string","values":["Level-1","Level-2","Level-3"]}]' ;;
      2) CLASS="PRIVACY GUARD PROTOCOL"
         JUNCTIONS='[{"field":"extracted_email","type":"string","pattern":"CLEAN_PII"},{"field":"Message_Origin_Date","type":"string","pattern":"STANDARD_DATE"}]' ;;
      3) CLASS="DEPARTMENTAL REFINERY"
         JUNCTIONS='[{"field":"department_type","type":"string","values":["Legal","HR","Tech","Operations"]}]' ;;
      4) read -p "Enter path to <blueprint.json>: " B_PATH
         [[ ! -f "$B_PATH" ]] && echo "ERROR: BLUEPRINT NOT FOUND" && exit 1
         # Extracting class and junctions from the nested 'blueprint' object
         CLASS=$(python3 -c "import json; b=json.load(open('$B_PATH')).get('blueprint', {}); print(b.get('class', 'CUSTOM INDUSTRIAL BLUEPRINT'))")
         JUNCTIONS=$(python3 -c "import json; b=json.load(open('$B_PATH')).get('blueprint', {}); print(json.dumps(b.get('junctions', [])))") ;;
      *) echo "FRACTURE: Invalid choice."; exit 1 ;;
    esac
fi

# --- STEP 2: DIRECT INJECTION ---
echo -n "[2/5] CASTING & IGNITING REACTOR: ["

# THE BLUEPRINT REPAIR: We nest the architecture and data for the Foundry
RESPONSE_FILE=$(mktemp)
python3 -c "import csv, json, sys; \
r=csv.DictReader(open('$CSV_FILE', 'r')); \
# THE ENTROPY: Extraction from the raw Ore
d=[{'id': i+1, '$COL_NAME': row['$COL_NAME'].replace('\n', ' ')} for i, row in enumerate(r) if i < $LIMIT]; \
# THE ARCHITECTURE: Nesting the Blueprint and Junctions
print(json.dumps({ \
    'blueprint': { \
        'class': '$CLASS', \
        'junctions': $JUNCTIONS \
    }, \
    'data': d \
}))" | \
curl -si -X POST "http://$SERVER_IP:8000/v1/synthesize" \
-H "Content-Type: application/json" \
-H "X-API-KEY: $API_KEY" \
-d @- > "$RESPONSE_FILE" 2>&1 &

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
    echo "FRACTURE: THE REACTOR REFUSED THE BLUEPRINT (422). Architecture invalid."
    
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
        sleep 0.1
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
        echo -e "\n"
        break
    fi
    sleep 0.1
done


# --- STEP 4: SECURING GAVEL-VERIFIED CONTRACT ---
echo -n "[4/5] SECURING GAVEL-VERIFIED CONTRACT: ["

# THE BLUEPRINT REPAIR: Default to true unless explicitly set to false
REMOTE=${REMOTE:-true}
RAW_FILENAME="data/chute/$BATCH_ID.json"
mkdir -p "data/chute"

if [[ "$REMOTE" == "true" ]]; then
    # We use -f to fail fast if the Reactor hasn't bit-for-bit sealed the JSON Contract
    curl -s -f -o "$RAW_FILENAME" "http://$SERVER_IP:8000/v1/results/$BATCH_ID"
fi

for i in {1..20}; do echo -n "#"; sleep 0.02; done
echo "] COMPLETE"

# --- STEP 5: GENERATING THE INDUSTRIAL CoA ---
echo -n "[5/5] GENERATING CERTIFICATE OF ANALYSIS: ["
CERT_FILENAME="data/chute/$BATCH_ID-COA.pdf"

if [[ "$REMOTE" == "true" ]]; then
    # THE SETTLING PULSE: We poll for up to 5s to ensure the PDF Ore is Smelt
    for i in {1..5}; do
        # THE RENDERING JUNCTION: Pulling the official Certificate of Analysis
        curl -s -f -o "$CERT_FILENAME" "http://$SERVER_IP:8000/v1/render/pdf/$BATCH_ID"
        [[ -s "$CERT_FILENAME" ]] && break
        echo -n "#"
        sleep 1.0
    done
fi

echo "####################] COMPLETE"

echo "--------------------------------------------------------"
echo "REFINERY STATUS: QUIESCENT | BATCH: $BATCH_ID COMPLETE"
echo "CONTRACT SECURED: $RAW_FILENAME"
echo "CERTIFICATE (CoA): $CERT_FILENAME"
echo "--------------------------------------------------------"

# --- STEP 6: PHYSICAL AUTO-OPEN ---
# We check if the CoA has MASS before igniting the viewer
if [ -s "$CERT_FILENAME" ]; then
    case "$OSTYPE" in
      darwin*)  open "$CERT_FILENAME" ;; 
      linux*)   xdg-open "$CERT_FILENAME" >/dev/null 2>&1 & ;;
      msys*|cygwin*) start "$CERT_FILENAME" ;;
      *)        echo "MANUAL AUDIT REQUIRED: $CERT_FILENAME" ;;
    esac
else
    echo "ERROR: FRACTURE DETECTED. THE CoA IS WEIGHTLESS (0 bytes)."
fi

