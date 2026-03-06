#!/bin/bash


SERVER_IP=${Z_SERVER_IP}
API_KEY=${Z_BETA_KEY}

CSV_FILE=$1
COL_NAME=$2
CUSTOM_SCHEMA_PATH=$4
SERVER_IP=${5:-$Z_SERVER_IP}
BETA_KEY=${6:-$Z_BETA_KEY}

LIMIT=${3:-50}

if ! command -v python3 &> /dev/null; then
    echo "ERROR: PYTHON 3 NOT DETECTED. THE OBSIDIAN REACTOR REQUIRES A PYTHON CORE FOR INDUCTION."
    exit 1
fi


if [ -z "$SERVER_IP" ] || [ -z "$BETA_KEY" ]; then
    echo "ERROR: REACTOR OFFLINE. SET Z_SERVER_IP AND Z_BETA_KEY TO IGNITE."
    exit 1
fi


# 1. THE DATA SIPHON: Buffer the pipe into the environment
export Z_RAW_ORE=$(cat "$CSV_FILE")

# 2. THE ALPHA REPAIR: Audit the headers via the Environment Vault
echo -n "[0/5] AUDITING ORE HEADERS... "
COLUMNS=$(python3 <<'EOF'
import csv, io, os, sys
try:
    # We fetch the ore from the environment to prevent Unicode Fractures
    r = csv.reader(io.StringIO(os.environ['Z_RAW_ORE']))
    print(next(r))
except Exception:
    sys.exit(1)
EOF
)

echo "DETECTED: $COLUMNS"

# 3. THE GASKET: Verify the target 'message' is in that manifest
if [[ ! "$COLUMNS" == *"$COL_NAME"* ]]; then
    echo "--------------------------------------------------------"
    echo "ERROR: COLUMN IDENTITY FRACTURE"
    echo "TARGET: '$COL_NAME' NOT FOUND IN MANIFEST."
    echo "--------------------------------------------------------"
    exit 1
fi


# --- STEP 0: KINETIC GUARDS ---
if [ -z "$2" ]; then 
    echo "Usage: Z_SERVER_IP=x Z_BETA_KEY=y ./zedacta.sh <csv_file> <column_name> <limit> [optional_schema_path]"
    exit 1
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 1 ] || [ "$LIMIT" -gt 50 ]; then
    echo "ERROR: INVALID BATCH SIZE ($LIMIT). DEMO LIMIT: 1-50."
    exit 1
fi

# Pre-flight Column Validation
COL_CHECK=$(python3 -c "import csv; f=open('$CSV_FILE', 'r'); h=next(csv.reader(f)); print('VALID' if '$COL_NAME' in h else 'INVALID:'+str(h)); f.close()")
if [[ "$COL_CHECK" == INVALID* ]]; then
    echo "ERROR: Column '$COL_NAME' not found in $CSV_FILE"; exit 1
fi

# --- STEP 1: MOLD SELECTION ---
echo "[1/5] SELECTING ZEDACTA MOLD..."

if [ -n "$CUSTOM_SCHEMA_PATH" ] && [ "$CUSTOM_SCHEMA_PATH" != "-" ]; then
    CLASS=$(python3 -c "import json, os; print(json.load(open(os.environ['CUSTOM_SCHEMA_PATH'])).get('blueprint_class', 'CUSTOM INDUSTRIAL MOLD'))")
    SCHEMA=$(python3 -c "import json, os; print(json.dumps(json.load(open(os.environ['CUSTOM_SCHEMA_PATH']))['schema_definition']))")
else
    echo "SELECT YOUR ZEDACTA MOLD:"
    echo "1) THE COMPLIANCE AUDITOR  (HYBRID)"
    echo "2) THE PRIVACY GUARD       (PHYSICAL)"
    echo "3) DEPARTMENTAL AUDIT      (SEMANTIC)"
    echo "4) CUSTOM INDUSTRIAL MOLD  (FILE)"
    read -p "Choice [1-4]: " MOLD_CHOICE
    
    case $MOLD_CHOICE in
      1) CLASS="COMPLIANCE AUDITOR (HYBRID)"
         SCHEMA='[{"field":"extracted_email","type":"string","pattern":"CLEAN_PII"},{"field":"severity_danger_level","type":"string","values":["Level-1","Level-2","Level-3"]}]' ;;
      2) CLASS="PRIVACY GUARD (PHYSICAL)"
         SCHEMA='[{"field":"extracted_email","type":"string","pattern":"CLEAN_PII"},{"field":"Message_Origin_Date","type":"string","pattern":"STANDARD_DATE"}]' ;;
      3) CLASS="DEPARTMENTAL AUDIT (SEMANTIC)"
         SCHEMA='[{"field":"department_type","type":"string","values":["Legal","HR","Tech","Operations"]}]' ;;
      4) read -p "Enter path to <schema.json>: " SCHEMA_PATH
         [[ ! -f "$SCHEMA_PATH" ]] && echo "ERROR: FILE NOT FOUND" && exit 1
         CLASS=$(python3 -c "import json; print(json.load(open('$SCHEMA_PATH')).get('blueprint_class', 'CUSTOM INDUSTRIAL MOLD'))")
         SCHEMA=$(python3 -c "import json; print(json.dumps(json.load(open('$SCHEMA_PATH'))['schema_definition']))") ;;
      *) echo "FRACTURE: Invalid choice."; exit 1 ;;
    esac
fi

# --- STEP 2: DIRECT INJECTION ---
echo -n "[2/5] SMELTING DATA ORE... "

# THE ALPHA REPAIR: We "Armor" the data in the environment to prevent Python parsing errors
export Z_RAW_ORE=$(cat "$CSV_FILE")
export Z_COL="$COL_NAME"
export Z_LIMIT="$LIMIT"
export Z_SCHEMA="$SCHEMA"
export Z_CLASS="$CLASS"

PAYLOAD=$(python3 <<'EOF'
import csv, json, io, sys, os
try:
    # We Siphon the ore from the environment, bypassing string literal limits
    r = csv.DictReader(io.StringIO(os.environ['Z_RAW_ORE']))
    col = os.environ['Z_COL']
    limit = int(os.environ['Z_LIMIT'])
    
    d = [{'id': i+1, col: row[col].replace('\n', ' ')} for i, row in enumerate(r) if i < limit]
    
    print(json.dumps({
        'blueprint_class': os.environ['Z_CLASS'],
        'schema_definition': json.loads(os.environ['Z_SCHEMA']),
        'data': d
    }))
except KeyError:
    sys.exit(1)
EOF
)

if [[ $? -ne 0 ]]; then
    echo -e "\nERROR: Column '$COL_NAME' not found in the ore. Reactor Refusal."
    exit 1
fi

echo "COMPLETE."
echo -n "[2/5] IGNITING REACTOR: ["

# THE KINETIC STRIKE: Upload the validated payload
RESPONSE_FILE=$(mktemp)
echo "$PAYLOAD" | curl -si -X POST "http://$SERVER_IP:8000/v1/synthesize" \
-H "Content-Type: application/json" \
-H "X-API-KEY: $BETA_KEY" \
-d @- > "$RESPONSE_FILE" 2>&1 &

PID=$!
while kill -0 $PID 2>/dev/null; do
    echo -n "#"; sleep 0.2
done
echo "####################] COMPLETE"

RESPONSE=$(cat "$RESPONSE_FILE")
rm "$RESPONSE_FILE"


# 2. THE LICENSE PLATE EXTRACTION
BATCH_ID=$(echo "$RESPONSE" | grep -i 'X-Zedacta-Batch-ID' | awk '{print $2}' | tr -d '\r')

# 3. THE GAVEL STRIKE: Precision Extraction of the Error Message
if [[ -z "$BATCH_ID" ]]; then 
    echo "--------------------------------------------------------"
    echo "FRACTURE: THE REACTOR REFUSED THE ORE (422)"
    
    # THE ALPHA REPAIR: We target the 'msg' field specifically. 
    # This ignores the 'input' block containing the Enron CSV data.
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"msg":"[^"]*"' | head -n 1 | cut -d'"' -f4)
    
    if [[ -n "$ERROR_MSG" ]]; then
        echo "VERDICT: $ERROR_MSG"
    else
        # Fallback: If no msg found, show just the first 100 characters of detail
        echo "Structural Failure: Check the Reactor Logs."
        echo "$RESPONSE" | grep -o '{"detail":.*}' | cut -c1-200
    fi
    echo "--------------------------------------------------------"
    exit 1 
fi

# --- STEP 3: MONITORING PULSE ---
echo "[3/5] MONITORING KINETIC PULSE: $BATCH_ID"

# We initialize a 'Mechanical Flicker' for the waiting state
COUNTER=0
while true; do
    PULSE=$(curl -s "http://$SERVER_IP:8000/refinery/pulse/$BATCH_ID")
    
    # If the Reactor hasn't yielded the pulse yet (404 or Quiescent)
    # we show the 'Ignition Pattern'
    STATUS=$(echo "$PULSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status','Quiescent'))")

    if [[ "$STATUS" == "Quiescent" ]]; then
        DOTS=$(printf "%$(( (COUNTER % 3) + 1 ))s" | tr " " ".")
        printf "\033[H\033[JIGNITING REACTOR CORE%s\n" "$DOTS"
        ((COUNTER++))
        sleep 0.1
        continue
    fi

# THE LAMINAR PULSE: Clear and Print the real-time telemetry
OUTPUT=$(cat <<EOF
ZEDACTA PULSE
--------------------------------------------------------
$(echo "$PULSE" | python3 -m json.tool)
EOF
    )
    printf "\033[H\033[J%s\n" "$OUTPUT"

    if [[ "$STATUS" == "COMPLETED" ]]; then
        echo -e "\n"
        echo "[*] SMELT COMPLETE. SETTLING FORENSIC LEDGER..."
        sleep 3.0
        break
    fi
    sleep 0.1
done

echo -n "[4/5] SECURING GAVEL-VERIFIED LEDGER: ["
for i in {1..20}; do
    echo -n "#"
    sleep 0.02
done
echo "] COMPLETE"

RAW_FILENAME="data/chute/$BATCH_ID.json"
if [[ "${REMOTE:-false}" == "true" ]]; then
    curl -s -f -o "$RAW_FILENAME" "http://$SERVER_IP:8000/v1/results/$BATCH_ID"
fi

# --- STEP 5: GENERATING THE MANIFEST ---
# We use a 0.2s 'Snap' rail to lead directly into the PDF auto-open
echo -n "[5/5] GENERATING FORENSIC MANIFEST:   ["
for i in {1..20}; do
    echo -n "#"
    sleep 0.01
done
echo "] COMPLETE"


# 2. GENERATE THE CERTIFICATE OF ANALYSIS (PDF)
CERT_FILENAME="data/chute/$BATCH_ID-COA.pdf"
# --- STEP 5: GENERATING THE CoA ---
curl -s -o "$CERT_FILENAME" "http://$SERVER_IP:8000/v1/render/pdf/$BATCH_ID"
echo "--------------------------------------------------------"
echo "REFINERY STATUS: QUIESCENT | BATCH: $BATCH_ID COMPLETE"
echo "LEDGER SECURED: $RAW_FILENAME"
echo "AUDIT CERTIFICATE: $CERT_FILENAME"
echo "--------------------------------------------------------"

# Auto-open the Certificate for the user
open "$CERT_FILENAME" 2>/dev/null || xdg-open "$CERT_FILENAME" 2>/dev/null

