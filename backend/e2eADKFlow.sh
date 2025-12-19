#!/bin/bash

# E2E ADK Flow Test Script - Interactive Wizard
# Guides you through creating a story with hint-driven images
#
# Usage: ./e2eADKFlow.sh

BASE_URL="http://localhost:3000/api/flow-test"

# Create saves directory in project root
SAVES_DIR="$(dirname "$0")/../saves"
mkdir -p "$SAVES_DIR"

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper function to parse JSON using Node.js
json_get() {
  echo "$1" | node -e "
    let data = '';
    process.stdin.on('data', chunk => data += chunk);
    process.stdin.on('end', () => {
      try {
        const obj = JSON.parse(data);
        const path = '$2'.split('.');
        let val = obj;
        for (const key of path) {
          if (val === null || val === undefined) break;
          val = val[key];
        }
        if (Array.isArray(val)) {
          console.log(val.join(', '));
        } else {
          console.log(val ?? '');
        }
      } catch (e) {
        console.log('');
      }
    });
  "
}

# Helper to pretty print JSON
json_print() {
  echo "$1" | node -e "
    let data = '';
    process.stdin.on('data', chunk => data += chunk);
    process.stdin.on('end', () => {
      try {
        console.log(JSON.stringify(JSON.parse(data), null, 2));
      } catch (e) {
        console.log(data);
      }
    });
  "
}

# Ask with validation helper
ask_with_validation() {
  local prompt="$1"
  local validation_regex="$2"
  local error_msg="$3"
  local default="$4"
  local result=""

  while true; do
    if [ -n "$default" ]; then
      echo -en "${CYAN}$prompt${NC} [${default}]: " >&2
    else
      echo -en "${CYAN}$prompt${NC}: " >&2
    fi
    read -r result

    # Use default if empty
    if [ -z "$result" ] && [ -n "$default" ]; then
      result="$default"
    fi

    # Validate
    if [ -z "$result" ]; then
      echo -e "${RED}Error: This field is required${NC}" >&2
    elif [[ "$result" =~ $validation_regex ]]; then
      echo "$result"
      return 0
    else
      echo -e "${RED}Error: $error_msg${NC}" >&2
    fi
  done
}

clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}        ${YELLOW}LogicTales Story Generator${NC}                         ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}        Interactive Wizard with Hint-Driven Images         ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Topic
echo -e "${GREEN}Step 1/6: What topic would you like to teach?${NC}"
echo -e "  (e.g., \"how computers work\", \"why is the sky blue\")"
TOPIC=$(ask_with_validation "Topic" "^.{3,}$" "Topic must be at least 3 characters" "")
echo ""

# Step 2: Art Style
echo -e "${GREEN}Step 2/6: Choose an art style${NC}"
echo -e "  ${CYAN}[1]${NC} pixel    - Retro pixel art style"
echo -e "  ${CYAN}[2]${NC} fantasy  - Magical fantasy illustrations"
echo -e "  ${CYAN}[3]${NC} cartoon  - Fun cartoon style"
while true; do
  echo -en "${CYAN}Enter choice${NC} [1-3]: "
  read -r choice
  case "$choice" in
    1) ART_STYLE="pixel"; break ;;
    2) ART_STYLE="fantasy"; break ;;
    3) ART_STYLE="cartoon"; break ;;
    *) echo -e "${RED}Invalid choice. Please enter 1, 2, or 3${NC}" ;;
  esac
done
echo -e "  Selected: ${YELLOW}$ART_STYLE${NC}"
echo ""

# Step 3: Target Age
echo -e "${GREEN}Step 3/6: Target age group${NC}"
echo -e "  ${CYAN}[1]${NC} 5-8    - Young children"
echo -e "  ${CYAN}[2]${NC} 8-12   - Middle school"
echo -e "  ${CYAN}[3]${NC} 13-17  - Teenagers"
echo -e "  ${CYAN}[4]${NC} 18+    - Adults"
echo -e "  ${CYAN}[5]${NC} all    - All ages"
while true; do
  echo -en "${CYAN}Enter choice${NC} [1-5]: "
  read -r choice
  case "$choice" in
    1) TARGET_AGE="5-8"; break ;;
    2) TARGET_AGE="8-12"; break ;;
    3) TARGET_AGE="13-17"; break ;;
    4) TARGET_AGE="18+"; break ;;
    5) TARGET_AGE="all"; break ;;
    *) echo -e "${RED}Invalid choice. Please enter 1-5${NC}" ;;
  esac
done
echo -e "  Selected: ${YELLOW}$TARGET_AGE${NC}"
echo ""

# Step 4: Page Count
echo -e "${GREEN}Step 4/6: How many pages?${NC}"
while true; do
  echo -en "${CYAN}Enter page count${NC} [1-5, default: 3]: "
  read -r PAGE_COUNT
  PAGE_COUNT="${PAGE_COUNT:-3}"
  if [[ "$PAGE_COUNT" =~ ^[1-5]$ ]]; then
    break
  else
    echo -e "${RED}Page count must be between 1 and 5${NC}"
  fi
done
echo -e "  Selected: ${YELLOW}$PAGE_COUNT pages${NC}"
echo ""

# Step 5: Per-page hints
echo -e "${GREEN}Step 5/6: Enter a hint for each page${NC}"
echo -e "  (The hint guides what concept the image will visually represent)"
echo -e "  Examples: \"if statement\", \"for loop\", \"phishing\", \"compound interest\""
echo ""

PAGE_HINTS=()
for ((i=1; i<=PAGE_COUNT; i++)); do
  echo -en "${CYAN}Page $i hint${NC}: "
  read -r hint
  if [ -z "$hint" ]; then
    hint="discovery"
  fi
  PAGE_HINTS+=("$hint")
done
echo ""

# Step 6: Review and confirm
echo -e "${GREEN}Step 6/6: Review and confirm${NC}"
echo -e "${BLUE}───────────────────────────────────────────${NC}"
echo -e "  Topic:    ${YELLOW}$TOPIC${NC}"
echo -e "  Style:    ${YELLOW}$ART_STYLE${NC}"
echo -e "  Age:      ${YELLOW}$TARGET_AGE${NC}"
echo -e "  Pages:    ${YELLOW}$PAGE_COUNT${NC}"
echo -e "  Hints:"
for ((i=0; i<${#PAGE_HINTS[@]}; i++)); do
  echo -e "    Page $((i+1)): ${YELLOW}${PAGE_HINTS[$i]}${NC}"
done
echo -e "${BLUE}───────────────────────────────────────────${NC}"
echo ""

while true; do
  echo -en "${CYAN}Generate story? [y/n]${NC}: "
  read -r confirm
  case "$confirm" in
    [yY]|[yY][eE][sS]) break ;;
    [nN]|[nN][oO]) echo "Cancelled."; exit 0 ;;
    *) echo -e "${RED}Please enter y or n${NC}" ;;
  esac
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Starting story generation...${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""

# Build JSON payload using Node.js to properly escape everything
REQUEST_JSON=$(node -e "
  const topic = process.argv[1];
  const artStyle = process.argv[2];
  const targetAge = process.argv[3];
  const pageCount = parseInt(process.argv[4], 10);
  const hints = process.argv.slice(5);
  console.log(JSON.stringify({
    topic,
    artStyle,
    targetAge,
    pageCount,
    pageHints: hints
  }));
" "$TOPIC" "$ART_STYLE" "$TARGET_AGE" "$PAGE_COUNT" "${PAGE_HINTS[@]}")

# Sanitize topic for filename
SAFE_TOPIC=$(echo "$TOPIC" | tr ' ' '-' | tr -cd '[:alnum:]-')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$SAVES_DIR/${SAFE_TOPIC}_${TIMESTAMP}.json"

# Step 1: Start the flow
echo -e "${GREEN}[1/4] Starting flow...${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/start" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_JSON")

SESSION_ID=$(json_get "$RESPONSE" "sessionId")

if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" == "null" ] || [ "$SESSION_ID" == "undefined" ]; then
  echo -e "${RED}ERROR: Failed to get session ID${NC}"
  json_print "$RESPONSE"
  exit 1
fi

echo -e "  Session: ${CYAN}$SESSION_ID${NC}"

# Step 2: Confirm
echo -e "${GREEN}[2/4] Enhancing story prompt...${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/confirm" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"$SESSION_ID\", \"answer\": \"yes\"}")

echo -e "  Character: ${CYAN}$(json_get "$RESPONSE" "prompts.suggestedCharacter")${NC}"

# Step 3: Generate cover
echo -e "${GREEN}[3/4] Generating cover image...${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/generate-cover" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"$SESSION_ID\", \"answer\": \"yes\"}")

echo -e "  Cover: ${CYAN}$(json_get "$RESPONSE" "coverImage.cloudinaryUrl")${NC}"

# Step 4: Generate pages (this takes a while)
echo -e "${GREEN}[4/4] Generating $PAGE_COUNT page images with hints...${NC}"
echo -e "  ${YELLOW}(This may take a few minutes)${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/generate-pages" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"$SESSION_ID\", \"answer\": \"yes\"}")

SUCCESS=$(json_get "$RESPONSE" "success")
if [ "$SUCCESS" != "true" ]; then
  echo -e "${RED}ERROR: Failed to generate pages${NC}"
  json_print "$RESPONSE"
  exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  SUMMARY${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo -e "Topic: ${YELLOW}$(json_get "$RESPONSE" "summary.topic")${NC}"
echo -e "Art Style: ${YELLOW}$(json_get "$RESPONSE" "summary.artStyle")${NC}"
echo -e "Character: ${YELLOW}$(json_get "$RESPONSE" "summary.suggestedCharacter")${NC}"
echo ""

# Print images with hints
echo -e "${GREEN}Generated Images:${NC}"
echo "$RESPONSE" | node -e "
  let data = '';
  process.stdin.on('data', chunk => data += chunk);
  process.stdin.on('end', () => {
    try {
      const obj = JSON.parse(data);
      if (obj.summary && obj.summary.images) {
        obj.summary.images.forEach(img => {
          const page = img.page === 'cover' ? 'cover' : 'page ' + img.page;
          const hint = img.hint ? ' (hint: ' + img.hint + ')' : '';
          console.log('  [' + page + ']' + hint);
          console.log('    URL: ' + img.cloudinaryUrl);
          if (img.visualMetaphor) {
            console.log('    Metaphor: ' + img.visualMetaphor.substring(0, 60) + '...');
          }
        });
      }
    } catch (e) {}
  });
"

echo ""

# Save JSON file with downloaded images
echo -e "${GREEN}Downloading images and saving JSON...${NC}"

IMAGES_DIR="$(dirname "$0")/../images"
mkdir -p "$IMAGES_DIR"

echo "$RESPONSE" | node -e "
  const https = require('https');
  const fs = require('fs');
  const path = require('path');

  const imagesDir = process.argv[1];
  const timestamp = Date.now();

  function downloadImage(url, filename) {
    return new Promise((resolve, reject) => {
      const file = fs.createWriteStream(filename);
      https.get(url, (response) => {
        if (response.statusCode === 200) {
          response.pipe(file);
          file.on('finish', () => {
            file.close();
            resolve(filename);
          });
        } else {
          reject(new Error('HTTP ' + response.statusCode));
        }
      }).on('error', (err) => {
        fs.unlink(filename, () => {});
        reject(err);
      });
    });
  }

  async function processStory() {
    let data = '';
    for await (const chunk of process.stdin) {
      data += chunk;
    }

    const obj = JSON.parse(data);
    if (!obj.summary) {
      console.error('Error: No summary in response');
      process.exit(1);
    }

    const localPaths = {};

    // Download all images
    for (const img of obj.summary.images) {
      const pageLabel = img.page === 'cover' ? 'cover' : 'page' + img.page;
      const filename = path.join(imagesDir, pageLabel + '_' + timestamp + '.png');
      const relativePath = 'images/' + path.basename(filename);

      console.error('  Downloading ' + pageLabel + '...');
      try {
        await downloadImage(img.cloudinaryUrl, filename);
        localPaths[img.cloudinaryUrl] = relativePath;
      } catch (err) {
        console.error('    Failed: ' + err.message);
        localPaths[img.cloudinaryUrl] = img.cloudinaryUrl;
      }
    }

    // Build the loadable story format
    const coverImg = obj.summary.images.find(i => i.page === 'cover');
    const story = {
      title: obj.summary.suggestedCharacter ?
        obj.summary.suggestedCharacter.split(',')[0] + \"'s Adventure: \" + obj.summary.topic :
        \"The Amazing \" + obj.summary.topic + \" Adventure\",
      topic: obj.summary.topic,
      general_image_prompt: obj.summary.enhancedStoryPrompt,
      cover_image_path: coverImg ? localPaths[coverImg.cloudinaryUrl] : '',
      target_age: obj.summary.targetAge || '5-8',
      art_style: obj.summary.artStyle,
      pages: obj.summary.images
        .filter(i => i.page !== 'cover')
        .map((img, idx) => ({
          id: idx + 1,
          image_path: localPaths[img.cloudinaryUrl],
          image_prompt: img.enhancedPrompt,
          hint_text: img.hint || '',
          visual_metaphor: img.visualMetaphor || '',
          question_text: 'Did you understand this concept?',
          question_type: 'yesno',
          choice_labels: ['Yes', 'No'],
          correct_answer_is_yes: true
        })),
      generation: {
        source: 'ai',
        grounded_facts: obj.summary.keyThemes || [],
        source_urls: [],
        timestamp: new Date().toISOString()
      },
      critic_review: {
        approved: true,
        warnings: [],
        readabilityScore: 85
      }
    };

    console.log(JSON.stringify(story, null, 2));
  }

  processStory().catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
  });
" "$IMAGES_DIR" > "$OUTPUT_FILE"

if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
  echo ""
  echo -e "${GREEN}Saved to:${NC} ${CYAN}$OUTPUT_FILE${NC}"
else
  echo -e "${RED}Error: Failed to save JSON file${NC}"
  rm -f "$OUTPUT_FILE"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Flow Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
