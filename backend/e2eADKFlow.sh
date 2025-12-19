#!/bin/bash

# E2E ADK Flow Test Script
# Tests the linear story generation flow with yes/no questions
# Outputs JSON that can be loaded via the load button
#
# Usage: ./e2eADKFlow.sh [topic] [artStyle] [targetAge]
#   topic     - Story topic (default: "why is the sky blue")
#   artStyle  - Art style: fantasy, pixel, cartoon (default: fantasy)
#   targetAge - Target age: 5-8, 8-12, 13-17, 18+, all (default: 5-8)
#
# Examples:
#   ./e2eADKFlow.sh "quantum physics" "pixel" "18+"
#   ./e2eADKFlow.sh "how computers work" "cartoon" "13-17"
#   ./e2eADKFlow.sh "climate change" "fantasy" "all"

BASE_URL="http://localhost:3000/api/flow-test"
TOPIC="${1:-why is the sky blue}"
ART_STYLE="${2:-fantasy}"
TARGET_AGE="${3:-5-8}"

# Create saves directory in project root
SAVES_DIR="$(dirname "$0")/../saves"
mkdir -p "$SAVES_DIR"

# Sanitize topic for filename (replace spaces with dashes, remove special chars)
SAFE_TOPIC=$(echo "$TOPIC" | tr ' ' '-' | tr -cd '[:alnum:]-')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$SAVES_DIR/${SAFE_TOPIC}_${TIMESTAMP}.json"

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

echo "============================================"
echo "  E2E ADK Flow Test"
echo "============================================"
echo "Topic: $TOPIC"
echo "Art Style: $ART_STYLE"
echo "Target Age: $TARGET_AGE"
echo ""

# Step 1: Start the flow
echo "============================================"
echo "Step 1: Starting flow..."
echo "============================================"
RESPONSE=$(curl -s -X POST "$BASE_URL/start" \
  -H "Content-Type: application/json" \
  -d "{\"topic\": \"$TOPIC\", \"artStyle\": \"$ART_STYLE\", \"targetAge\": \"$TARGET_AGE\"}")

json_print "$RESPONSE"

SESSION_ID=$(json_get "$RESPONSE" "sessionId")

if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" == "null" ] || [ "$SESSION_ID" == "undefined" ]; then
  echo "ERROR: Failed to get session ID"
  exit 1
fi

echo ""
echo "Session ID: $SESSION_ID"
echo "Question: $(json_get "$RESPONSE" "question.text")"
echo "Hint: $(json_get "$RESPONSE" "question.hint")"
echo ""

# Step 2: Confirm and enhance story prompt
echo "============================================"
echo "Step 2: Confirming (answer: yes)..."
echo "============================================"
RESPONSE=$(curl -s -X POST "$BASE_URL/confirm" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"$SESSION_ID\", \"answer\": \"yes\"}")

json_print "$RESPONSE"

echo ""
echo "Original Prompt: $(json_get "$RESPONSE" "prompts.original")"
echo "Enhanced Prompt: $(json_get "$RESPONSE" "prompts.enhanced")"
echo "Suggested Character: $(json_get "$RESPONSE" "prompts.suggestedCharacter")"
echo "Key Themes: $(json_get "$RESPONSE" "prompts.keyThemes")"
echo ""
echo "Question: $(json_get "$RESPONSE" "question.text")"
echo "Hint: $(json_get "$RESPONSE" "question.hint")"
echo ""

# Step 3: Generate cover image
echo "============================================"
echo "Step 3: Generating cover image (answer: yes)..."
echo "============================================"
RESPONSE=$(curl -s -X POST "$BASE_URL/generate-cover" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"$SESSION_ID\", \"answer\": \"yes\"}")

json_print "$RESPONSE"

echo ""
echo "Cover Image:"
echo "  Original Prompt: $(json_get "$RESPONSE" "coverImage.originalPrompt")"
echo "  Enhanced Prompt: $(json_get "$RESPONSE" "coverImage.enhancedPrompt")"
echo "  Cloudinary URL: $(json_get "$RESPONSE" "coverImage.cloudinaryUrl")"
echo ""
echo "Question: $(json_get "$RESPONSE" "question.text")"
echo "Hint: $(json_get "$RESPONSE" "question.hint")"
echo ""

# Step 4: Generate page images
echo "============================================"
echo "Step 4: Generating page images (answer: yes)..."
echo "============================================"
RESPONSE=$(curl -s -X POST "$BASE_URL/generate-pages" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\": \"$SESSION_ID\", \"answer\": \"yes\"}")

json_print "$RESPONSE"

echo ""
echo "============================================"
echo "  SUMMARY"
echo "============================================"
echo ""
echo "Topic: $(json_get "$RESPONSE" "summary.topic")"
echo "Art Style: $(json_get "$RESPONSE" "summary.artStyle")"
echo "Enhanced Story Prompt: $(json_get "$RESPONSE" "summary.enhancedStoryPrompt")"
echo "Suggested Character: $(json_get "$RESPONSE" "summary.suggestedCharacter")"
echo "Key Themes: $(json_get "$RESPONSE" "summary.keyThemes")"
echo ""

# Print images summary
echo "Generated Images:"
echo "$RESPONSE" | node -e "
  let data = '';
  process.stdin.on('data', chunk => data += chunk);
  process.stdin.on('end', () => {
    try {
      const obj = JSON.parse(data);
      if (obj.summary && obj.summary.images) {
        obj.summary.images.forEach(img => {
          console.log('  [' + img.page + '] ' + img.cloudinaryUrl);
        });
      }
    } catch (e) {}
  });
"

echo ""
echo "All Prompts (Original -> Enhanced):"
echo "$RESPONSE" | node -e "
  let data = '';
  process.stdin.on('data', chunk => data += chunk);
  process.stdin.on('end', () => {
    try {
      const obj = JSON.parse(data);
      if (obj.summary && obj.summary.images) {
        obj.summary.images.forEach(img => {
          console.log('');
          console.log('  [' + img.page + '] Original: ' + img.originalPrompt);
          console.log('  [' + img.page + '] Enhanced: ' + img.enhancedPrompt);
        });
      }
    } catch (e) {}
  });
"

echo ""

# Save the loadable JSON file with downloaded images
echo "============================================"
echo "  Downloading images and saving JSON..."
echo "============================================"

# Create images directory in project root
IMAGES_DIR="$(dirname "$0")/../images"
mkdir -p "$IMAGES_DIR"

# Process response and download images
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

    const downloads = [];
    const localPaths = {};

    // Download all images
    for (const img of obj.summary.images) {
      const pageLabel = img.page === 'cover' ? 'cover' : 'page' + img.page;
      const filename = path.join(imagesDir, pageLabel + '_' + timestamp + '.png');
      const relativePath = 'images/' + path.basename(filename);

      console.error('Downloading ' + pageLabel + '...');
      try {
        await downloadImage(img.cloudinaryUrl, filename);
        localPaths[img.cloudinaryUrl] = relativePath;
        console.error('  Saved to: ' + relativePath);
      } catch (err) {
        console.error('  Failed: ' + err.message);
        localPaths[img.cloudinaryUrl] = img.cloudinaryUrl; // Keep URL as fallback
      }
    }

    // Build the loadable story format with local paths
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
          question_text: 'Are you sure?',
          hint_text: 'yes',
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
  echo "Saved to: $OUTPUT_FILE"
  echo ""
  echo "File contents:"
  cat "$OUTPUT_FILE"
else
  echo "Error: Failed to save JSON file"
  rm -f "$OUTPUT_FILE"
fi

echo ""
echo "============================================"
echo "  Flow Complete!"
echo "============================================"
