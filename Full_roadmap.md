This is the **Architectural Blueprint for "LogicTales"**.

As your Software Architect, I have broken this down into **5 Phases**. We build the **Core Engine** first (Local), then the **AI Tools**, and finally the **Cloud Infrastructure** (Hono).

---

### **Recommended Library Stack (LÖVE Client)**
Download these and place them in your project’s `libraries/` folder before starting.

1.  **UI Framework:** **[Slab](https://github.com/coding-jackalope/Slab)**
    *   *Why:* It is an "Immediate Mode" GUI. Perfect for the "Creator Dashboard" (Input boxes, sliders, windows). It is pure Lua and easy to integrate.
2.  **Networking:** **[lua-https](https://github.com/jakobwesthoff/love-https)** (or `luasec`)
    *   *Why:* LÖVE cannot make HTTPS requests out of the box. You need this to talk to OpenAI and your Hono backend.
3.  **Data Serialization:** **[rxi/json](https://github.com/rxi/json.lua)**
    *   *Why:* To save stories as `.json` files and send data to the API.
4.  **Async Management:** **[love.thread](https://love2d.org/wiki/love.thread)** (Built-in)
    *   *Why:* Generating an AI image takes 5-10 seconds. We must use threads so the app doesn't freeze while waiting.

---

### **Phase 1: The Logic Engine (The "Player" Mode)**
**Objective:** Build the system that reads a JSON file and lets a user play through it. No AI generation yet, just placeholders.

**Granular Steps:**
1.  **Define the Data Schema:**
    *   Create `schema.lua`. Define the structure of a "Page":
        *   `image_path` (string)
        *   `question_text` (string)
        *   `variable_name` (e.g., "apples")
        *   `variable_value` (e.g., 4)
        *   `condition` (e.g., "> 3")
        *   `true_destination_id` (int)
        *   `false_destination_id` (int)
2.  **State Management:**
    *   Create `gamestate.lua`.
    *   Implement a `current_page` pointer.
    *   Implement a `variables` table (e.g., `{ apples = 4 }`).
3.  **The Renderer:**
    *   Draw a placeholder rectangle (where the AI image will go).
    *   Draw the `question_text` at the bottom.
    *   Draw two large buttons: "Left" and "Right" (or custom text based on the story).
4.  **The Logic Processor:**
    *   Write a function `evaluateLogic(condition, value, user_choice)`.
    *   *Example:* Lua's `loadstring` can be dangerous. Instead, write a simple parser: `if operator == ">" and current_val > target_val then...`
5.  **The Win/Lose Loop:**
    *   Handle the transition. If logic is correct -> Load `true_destination_id`.

---

### **Phase 2: The Creator Studio (The UI)**
**Objective:** Allow a user to create the JSON file via a GUI instead of writing code.

**Granular Steps:**
1.  **Integrate Slab:**
    *   Initialize Slab in `love.load` and `love.update`.
2.  **Story Editor Layout:**
    *   Create a "Split View": Left side is the Form (Inputs), Right side is the Preview (Game View).
    *   Add Input Fields: "Story Title", "Page ID".
3.  **Page Editor:**
    *   Add Inputs: Question Text, Hint Text.
    *   Add Logic Config: Dropdown for Operator (`>`, `<`, `=`), Input for Value.
4.  **Asset Management:**
    *   Add a "Save Story" button.
    *   Use `love.filesystem.write` to save the table as `my_story.json` in the save directory.
    *   Add a "Load Story" button to list files in the directory.

---

### **Phase 3: The AI Pipeline (BYOK Integration)**
**Objective:** Connect the Creator Studio to OpenAI (DALL-E 3) to generate assets.

**Granular Steps:**
1.  **Settings Menu:**
    *   Create a secure input field in Slab for "OpenAI API Key".
    *   Save this key locally to `settings.json` (exclude this file from git!).
2.  **The Prompt Engineer:**
    *   Create a text field for "Image Description" (e.g., "A magical forest").
    *   *Architectural Note:* Append a hidden suffix to all prompts to ensure style consistency (e.g., "... in a vibrant, children's book illustration style, vector art").
3.  **The Networking Thread:**
    *   Create a new file `download_thread.lua`.
    *   Pass the API Key and Prompt to this thread.
    *   The thread sends a POST request to OpenAI `v1/images/generations`.
4.  **Image Handling:**
    *   Receive the JSON response (URL).
    *   Download the image binary data.
    *   Save it to `love.filesystem.getSaveDirectory() / "images" / "page_1.png"`.
    *   Pass a message back to the main thread: "Image Ready".
5.  **Hot Reloading:**
    *   When "Image Ready" is received, reload the image asset in the Preview window.

---

### **Phase 4: The Backend (Hono + Supabase)**
**Objective:** The "Marketplace" to share stories.

**Granular Steps:**
1.  **Setup Hono:**
    *   Initialize a Hono project (`npm create hono@latest`).
    *   Install `@supabase/supabase-js`.
2.  **Database Schema (Supabase):**
    *   Table `users`: `id`, `email`, `is_supporter` (boolean).
    *   Table `stories`: `id`, `title`, `author_id`, `json_data` (JSONB), `downloads` (int).
3.  **API Endpoint - GET /stories:**
    *   Fetch latest 20 stories from DB.
    *   Return JSON array (Title, Author, ID).
4.  **API Endpoint - POST /publish:**
    *   Accept JSON body.
    *   **Middleware:** Check `Authorization` header. Verify user exists in DB.
    *   **Logic:** `if user.is_supporter == false` return 403 Forbidden.
    *   Insert story into DB.
5.  **API Endpoint - GET /story/:id:**
    *   Fetch specific JSON data for a story so the Client can download it.

---

### **Phase 5: The Marketplace Client (Integration)**
**Objective:** Connect LÖVE to Hono.

**Granular Steps:**
1.  **The Browser UI:**
    *   Create a new screen in LÖVE: "Online Library".
    *   On load, HTTP GET `your-hono-api.com/stories`.
    *   Render the list using Slab (Listbox or Grid).
2.  **Download Logic:**
    *   When a user clicks a story, HTTP GET `.../story/:id`.
    *   Save the received JSON body to `love.filesystem` as `downloaded_story.json`.
3.  **The Publisher:**
    *   In the Creator Studio, add a "Publish to Cloud" button.
    *   HTTP POST the current story JSON to `.../publish`.
    *   Handle errors (e.g., Show popup "Please Buy Me a Coffee to Publish!").

---

### **Summary of Tech Stack**

| Component | Technology | Library/Tool |
| :--- | :--- | :--- |
| **Game Engine** | LÖVE (Lua) | Core |
| **GUI** | Lua | **Slab** |
| **HTTP Client** | Lua | **lua-https** |
| **Backend API** | TypeScript | **Hono** |
| **Database** | PostgreSQL | **Supabase** |
| **Image Gen** | API | **OpenAI DALL-E 3** |

### **Where to start today?**
Start with **Phase 1, Step 1 & 2**.
Create `main.lua`, define the `story` table manually, and try to print the text to the screen. Do not worry about UI or AI yet. Get the data structure right.