/// @file: 
import std.conv, std.stdio, std.string, std.json, std.array, std.algorithm;

import bindbc.sdl;
import gameobject;
import component;
import factory;
import linear;
import scripts;
import resourcemanager;
import winscript, losescript, menuscript;

/// Represents a camera in the scene, with a transformation used to position and track the view.
class Camera{
    ComponentTransform mTransform;

    /// Constructs a new camera with a default transformation.
    this(){
        mTransform = new ComponentTransform(0);
    }

    /**
     * Sets the camera's position.
     * Params:
     *  x = x-coordinate of camera center
     *  y = y-coordinate of camera center
     */
    void PositionCamera(float x, float y){
        mTransform.mLocalMatrix = MakeTranslate(x,y);
    }

    /**
     * Returns the camera's current world position.
     * Returns: A Vec2f representing the camera's translation.
     */
    Vec2f GetPosition(){
        Vec2f result = mTransform.mLocalMatrix.Frommat3GetTranslation();
        return result;
    }

    /**
     * Clamps a value between a minimum and maximum.
     * Params:
     *  val = value to clamp
     *  min = lower bound
     *  max = upper bound
     * Returns: Clamped value
     */
    float Clamp(float val, float min, float max) {
        return (val < min) ? min : (val > max) ? max : val;
    }

    /**
     * Repositions the camera to center on the player while staying within map bounds.
     * Params:
     *  playerPos = world position of the player
     *  camWidth = width of camera viewport
     *  camHeight = height of camera viewport
     *  mapWidth = total width of the map
     *  mapHeight = total height of the map
     */
    void CenterOnPlayerClamped(Vec2f playerPos, float camWidth, float camHeight, float mapWidth, float mapHeight) {
        // Horizontal follow + clamp
        float camX = -playerPos.x + camWidth / 2;
        float minCamX = -(mapWidth - camWidth);
        camX = Clamp(camX, minCamX, 0);

        // Lock Y to show full vertical map
        float camY = -(mapHeight - camHeight) / 2;

        PositionCamera(camX, camY);
    }
}

/// Represents a node in the scene tree.
/// Each node optionally holds a GameObject and can have named child nodes.
struct TreeNode {
    TreeNode*[string] children;
    GameObject* object;

    /// Constructs a TreeNode with an associated GameObject.
    this(GameObject* obj) {
        object = obj;
    }

    /**
     * Performs a depth-first search traversal on the scene tree.
     * Params:
     *  objectFunc = delegate to apply to each GameObject
     *  topDown = whether to apply function pre-order (true) or post-order (false)
     */
    void DFS(void delegate(GameObject*) objectFunc, bool topDown=true) {
        if (topDown) {
            if (object !is null) {
                objectFunc(object);
            }
        }
        foreach (TreeNode* c ; children) {
            c.DFS(objectFunc, topDown);
        }
        if (!topDown) {
            if (object !is null) {
                objectFunc(object);
            }
        }
    }
}


/// SceneTree manages a hierarchy of game objects as a tree.
/// It supports JSON loading and serialization, update traversal, and rendering.
struct SceneTree {
    SDL_Renderer* mRendererRef;
    TreeNode* mRoot;
    GameObject[] mGameObjects;

    /// Constructs a SceneTree with a reference to an SDL renderer and an initial number of objects.
    this(SDL_Renderer* r, int objects) {
        mRendererRef = r;
        mRoot = new TreeNode(null);
    }

    // Loads the scene tree from a JSON structure.
    void loadFromJSON(JSONValue j) {
        // Load objects
        GameObject*[string] objPtrs;
        foreach(objectJSON ; j["objects"].array) {
            // writeln(objectJSON["name"].str);
            mGameObjects ~= new GameObject(objectJSON["name"].str);
            mGameObjects[$-1].loadFromJSON(objectJSON);
            objPtrs[objectJSON["name"].str] = &(mGameObjects[$-1]);

            // Handle component interdependencies
            auto o = mGameObjects[$-1];
            if (ComponentType.TEXT in o.mComponents && ComponentType.TEXTURE in o.mComponents) {
                auto texture = cast(ComponentTexture)o.GetComponent(ComponentType.TEXTURE);
                auto text = cast(ComponentText)o.GetComponent(ComponentType.TEXT);
                text.mTextureRef = &texture;
                text.mRenderer = mRendererRef;
                text.UpdateTexture();
			}
        }
        // Set up tree structure
        TreeNode*[] nodes = [mRoot];
        foreach(nodeJSON ; j["treeNodes"].array) {
            TreeNode* node;
            if ("objName" in nodeJSON) {
                node = new TreeNode(objPtrs[nodeJSON["objName"].str]);
            } else {
                node = new TreeNode(null);
            }
            nodes[nodeJSON["parent"].integer].children[nodeJSON["name"].str] = node;
            nodes ~= node;
        }
    }

    /// Serializes the scene tree to a JSON object.
    JSONValue toJSON() {
        JSONValue[] objectJSONs = mGameObjects.map!(o => o.toJSON()).array;

        int[TreeNode*] nodeIndices;
        nodeIndices[mRoot] = 0;
        // Use queue (array with index of front) to DFS and store node info
        TreeNode*[] nodeQ = [mRoot];
        int index = 0;
        JSONValue[] nodeJSONs = [];
        while(index < nodeQ.length) {
            foreach(name, child ; nodeQ[index].children) {
                nodeJSONs ~= JSONValue(["name": name]);
                nodeJSONs[$-1].object["parent"] = index;
                if(child.object !is null){
                    nodeJSONs[$-1].object["objName"] = child.object.GetName();
                }
                nodeQ ~= child;
            }
            index++;
        }
        JSONValue j = ["objects": objectJSONs, "treeNodes": nodeJSONs];
        return j;
    }

    // Loads a test world with various sprites and objects.
    // void LoadWorld(int objects){
    //     // Make a bounding box to represent the world
    //     GameObject world =  MakeSprite("world"); 
    //     auto col= cast(ComponentCollision)world.GetComponent(ComponentType.COLLISION);
    //     auto transform= cast(ComponentTransform)world.GetComponent(ComponentType.TRANSFORM);
    //     auto tex = cast(ComponentTexture)world.GetComponent(ComponentType.TEXTURE);
    //     tex.mRect.w = 2880;
    //     tex.mRect.h = 480;
    //     col.mRect.w = 2880;
    //     col.mRect.h = 480;
    //     tex.SetTexture("assets/images/map.png");
    //     AddObject([], "world", world);

    //     // Create some different game objects from a factory
    //     TTF_Font* font = TTF_OpenFont("assets/fonts/Jersey15-Regular.ttf", 24);
    //     if (font is null) {
    //         writeln("Failed to load font: ", TTF_GetError().fromStringz);
    //     }

    //     // Make the main character
    //     GameObject player = MakeAnimatedSprite("MainPlayer");
    //     assert(GameObject.GetGameObject("MainPlayer") !is null);
    //     player.mScripts ~= new PlayerScript(player.GetID());

    //     transform= cast(ComponentTransform)player.GetComponent(ComponentType.TRANSFORM);
    //     // Sebastian's transform
    //     // transform.Translate(70,200);
    //     transform.Translate(70, 255); // Roughly centered vertically on carpet

    //     tex = cast(ComponentTexture)player.GetComponent(ComponentType.TEXTURE);
    //     col  = cast(ComponentCollision)player.GetComponent(ComponentType.COLLISION);
    //     auto animatedtex = cast(ComponentAnimatedTexture)player.GetComponent(ComponentType.ANIMATEDTEXTURE);
    //     tex.mRect.w = 50;
    //     tex.mRect.h = 50;
    //     col.mRect.w = 30;
    //     col.mRect.h = 20;
    //     col.SetOffset(15,15);

    //     tex.SetTexture("assets/images/player_spritesheet.png");
    //     animatedtex.SetTexture("assets/images/player.json");
    //     animatedtex.ChangeAnimationSequence("run");

    //     AddObject([], "player", player);

    //     GameObject enemy = MakeAnimatedSprite("Enemy");
    //     assert(GameObject.GetGameObject("Enemy") !is null);
    //     enemy.mScripts ~= new EnemyScript(enemy.GetID());
    //     auto transform2 = cast(ComponentTransform)enemy.GetComponent(ComponentType.TRANSFORM);
    //     auto tex2 = cast(ComponentTexture)enemy.GetComponent(ComponentType.TEXTURE);
    //     auto col2  = cast(ComponentCollision)enemy.GetComponent(ComponentType.COLLISION);
    //     auto animatedtex2 = cast(ComponentAnimatedTexture)enemy.GetComponent(ComponentType.ANIMATEDTEXTURE);
    //     tex2.mRect.w = 30;
    //     tex2.mRect.h = 40;
    //     col2.mRect.w = 30;
    //     col2.mRect.h = 40;
    //     transform2.Translate(300,250);
    //     tex2.SetTexture("assets/images/enemy_spritesheet.png");
    //     animatedtex2.SetTexture("assets/images/enemy.json");
    //     animatedtex2.ChangeAnimationSequence("run");

    //     AddObject([], "enemy", enemy);

    //     // Make the carpet

    //     GameObject carpet =  MakeBoundingBox("carpet"); 
    //     col = cast(ComponentCollision)carpet.GetComponent(ComponentType.COLLISION);
    //     transform = cast(ComponentTransform)carpet.GetComponent(ComponentType.TRANSFORM);
    //     transform.Translate(30,230);
    //     col.mRect.w = 2800;
    //     col.mRect.h = 115;
    //     AddObject([], "carpet", carpet);
    // }

    // Populates the tree with predefined objects and layout for a menu screen.
    // void LoadWorldMenu(){
    //     // Add menu screen
    //     GameObject menu = MakeBackdrop("menu");
    //     assert(GameObject.GetGameObject("menu") !is null);
        
    //     auto transform2 = cast(ComponentTransform)menu.GetComponent(ComponentType.TRANSFORM);
    //     auto tex2 = cast(ComponentTexture)menu.GetComponent(ComponentType.TEXTURE);
    //     tex2.mRect.w = 640;
    //     tex2.mRect.h = 480;
    //     transform2.Translate(0,0);
    //     tex2.SetTexture("assets/images/bg_menu.png");
    //     AddObject([], "menu", menu);
        
    //     // Create some different game objects from a factory
    //     TTF_Font* font = TTF_OpenFont("assets/fonts/Jersey15-Regular.ttf", 24);
    //     if (font is null) {
    //         writeln("Failed to load font: ", TTF_GetError().fromStringz);
    //     }

    //     auto title = CreateTextLabel(
    //         "title",
    //         "NIGHTMARE AT THE MUSEUM",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         50,
    //         Vec2f(80, 20),
    //         mRendererRef
    //     );
    //     AddObject([], "title", title);

    //     auto label1 = CreateTextLabel(
    //         "label1",
    //         "PRESS SPACE TO START",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(150, 80),
    //         mRendererRef
    //     );

    //     auto label2 = CreateTextLabel(
    //         "label2",
    //         "PRESS E TO EDIT LEVEL",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(150, 380),
    //         mRendererRef
    //     );
    //     auto label3 = CreateTextLabel(
    //         "label3",
    //         "Press Q to Quit",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(200, 420),
    //         mRendererRef
    //     );
    //     AddObject([], "label1", label1);
    //     AddObject([], "label2", label2);
    //     AddObject([], "label3", label3);
    // }

    // void LoadWorldWinScreen(){
    //     // Add menu screen
    //     GameObject winScreen = MakeBackdrop("winScreen");
    //     assert(GameObject.GetGameObject("winScreen") !is null);
        
    //     auto transform2 = cast(ComponentTransform)winScreen.GetComponent(ComponentType.TRANSFORM);
    //     auto tex2 = cast(ComponentTexture)winScreen.GetComponent(ComponentType.TEXTURE);
    //     tex2.mRect.w = 640;
    //     tex2.mRect.h = 480;
    //     transform2.Translate(0,0);
    //     tex2.SetTexture("assets/images/bg_win.png");
    //     AddObject([], "winScreen", winScreen);

    //     // Create some different game objects from a factory
    //     TTF_Font* font = TTF_OpenFont("assets/fonts/Jersey15-Regular.ttf", 24);
    //     if (font is null) {
    //         writeln("Failed to load font: ", TTF_GetError().fromStringz);
    //     }

    //     auto label1 = CreateTextLabel(
    //         "label1",
    //         "Congratulations! You Escaped the Museum!",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         36,
    //         Vec2f(37, 60),
    //         mRendererRef
    //     );
    //     auto label2 = CreateTextLabel(
    //         "label2",
    //         "Press Space to Play Again",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(140, 380),
    //         mRendererRef
    //     );
    //     auto label3 = CreateTextLabel(
    //         "label3",
    //         "Press Q to Quit",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(200, 420),
    //         mRendererRef
    //     );
    //     AddObject([], "label1", label1);
    //     AddObject([], "label2", label2);
    //     AddObject([], "label3", label3);
    // }

    // void LoadWorldLoseScreen(){
    //     // Add menu screen
    //     GameObject loseScreen = MakeBackdrop("loseScreen");
    //     assert(GameObject.GetGameObject("loseScreen") !is null);
        
    //     auto transform2 = cast(ComponentTransform)loseScreen.GetComponent(ComponentType.TRANSFORM);
    //     auto tex2 = cast(ComponentTexture)loseScreen.GetComponent(ComponentType.TEXTURE);
    //     tex2.mRect.w = 640;
    //     tex2.mRect.h = 480;
    //     transform2.Translate(0,0);
    //     tex2.SetTexture("assets/images/bg_lose.png");
    //     AddObject([], "loseScreen", loseScreen);

    //     // Create some different game objects from a factory
    //     TTF_Font* font = TTF_OpenFont("assets/fonts/Jersey15-Regular.ttf", 24);
    //     if (font is null) {
    //         writeln("Failed to load font: ", TTF_GetError().fromStringz);
    //     }

    //     auto label1 = CreateTextLabel(
    //         "label1",
    //         "Oh No! You've Been Caught!",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         50,
    //         Vec2f(80, 60),
    //         mRendererRef
    //     );
    //     auto label2 = CreateTextLabel(
    //         "label2",
    //         "Press Space to Play Again",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(140, 380),
    //         mRendererRef
    //     );
    //     auto label3 = CreateTextLabel(
    //         "label3",
    //         "Press Q to Quit",
    //         "assets/fonts/Jersey15-Regular.ttf",
    //         40,
    //         Vec2f(200, 420),
    //         mRendererRef
    //     );
    //     AddObject([], "label1", label1);
    //     AddObject([], "label2", label2);
    //     AddObject([], "label3", label3);
    // }


    // Handles camera-relative input logic such as mouse clicks.
    void Input(Camera cam){
        // Get SDL Mouse coordinates
        int mouseX, mouseY;
        int mask = SDL_GetMouseState(&mouseX,&mouseY);
        Vec2f cameraPosition=cam.GetPosition();
    }

    // Updates all game objects and their transforms relative to the camera.
    void Update(Camera cam) {
        // Get the main player
        TreeNode* goNode = GetNode(["player"]);
        if (goNode !is null) {
            auto go = goNode.object;
            // Set the camera to center on the main player
            auto playerTransform= cast(ComponentTransform)go.GetComponent(ComponentType.TRANSFORM);
            Vec2f xy = playerTransform.mLocalMatrix.Frommat3GetTranslation();

            // Clamp camera to map
            int mapHeight = 480;
            int mapWidth = 2880;
            int viewportHeight = 480;
            int viewportWidth = 640;
            cam.CenterOnPlayerClamped(xy, viewportWidth, viewportHeight, mapWidth, mapHeight);
        }

        mRoot.DFS((GameObject* obj) {
			foreach(ref script ; obj.mScripts){
				script.Update();
			}
        });

        mRoot.DFS((GameObject* obj) {
            auto transform = cast(ComponentTransform)obj.GetComponent(ComponentType.TRANSFORM);
            transform.mWorldMatrix = transform.mLocalMatrix * cam.mTransform.mLocalMatrix; 
            if(transform !is null){
                transform.Update();
                // Update texture screen destination
                auto texture = cast(ComponentTexture)obj.GetComponent(ComponentType.TEXTURE);
                if(texture !is null){
                    Vec2f pos = transform.mWorldMatrix.Frommat3GetTranslation();
                    Vec2f scale = transform.GetScale();
                    float angle = transform.GetAngle();
                    texture.SetDest(pos, scale, angle);
                }
            }
        });

        // Render static textures
        mRoot.DFS((GameObject* obj) {
            auto col = cast(ComponentCollision)obj.GetComponent(ComponentType.COLLISION);
            if(col !is null){
                auto transform = cast(ComponentTransform)obj.GetComponent(ComponentType.TRANSFORM);
                Vec2f pos = transform.mWorldMatrix.Frommat3GetTranslation();
                col.SetPosition(cast(int)pos.x, cast(int)pos.y);
            }
        });
    }

    // Renders all visible components of the scene tree.
    void Render(){
        // Render animated textures
        foreach(obj ; mGameObjects){
            auto tex = cast(ComponentTexture)obj.GetComponent(ComponentType.TEXTURE);
            auto animatedtex = cast(ComponentAnimatedTexture)obj.GetComponent(ComponentType.ANIMATEDTEXTURE);
            if(animatedtex !is null){
                animatedtex.Render(mRendererRef);
            }
            else if(tex !is null){
                tex.Render(mRendererRef);
            }
        }
        
        // mRoot.DFS((GameObject* obj) {
        //     auto col = cast(ComponentCollision)obj.GetComponent(ComponentType.COLLISION);
        //     if(col !is null){
        //         auto transform = cast(ComponentTransform)obj.GetComponent(ComponentType.TRANSFORM);
        //         Vec2f pos = transform.mWorldMatrix.Frommat3GetTranslation();
        //         col.SetPosition(cast(int)pos.x, cast(int)pos.y);
        //     }
        // });
    }

    /**
     * Adds a game object to the scene tree at a specified path.
     * Params:
     *  path = array of node names leading to the target
     *  name = new name for the inserted object
     *  object = the GameObject to insert
     */
    void AddObject(string[] path, string name, GameObject object) {
        mGameObjects ~= object;
        TreeNode* curr = mRoot;
        foreach (string node ; path) {
            if (node !in curr.children) {
                curr.children[node] = new TreeNode(null);
            }
            curr = curr.children[node];
        }
        curr.children[name] = new TreeNode(&(mGameObjects[$-1]));
    }

    /**
     * Retrieves a TreeNode by its path in the tree.
     * Throws if path is invalid.
     * Returns: Pointer to the requested TreeNode
     */
    TreeNode* GetNode(string[] path) {
        TreeNode* curr = mRoot;
        foreach (string node ; path) {
            if (node !in curr.children) {
                return null;
            }
            curr = curr.children[node];
        }
        return curr;
    }
}

/// Store mappings of int, float, and strings to maps.
/// This data can keep track of various 'state' in your game and otherwise
/// be added to dynamically.
struct GameState{
    int[string]     mIntMap;
    float[string] 	mFloatMap;
    string[string] 	mStringMap;

    /// Loads state values from a JSON object.
    void loadFromJSON(JSONValue j){
        foreach(string k, JSONValue v ; j["ints"]) {
            mIntMap[k] = to!int(v.integer);
        }
        foreach(string k, JSONValue v ; j["floats"]) {
            mFloatMap[k] = v.floating;
        }
        foreach(string k, JSONValue v ; j["strings"]) {
            mStringMap[k] = v.str;
        }
    }

    /// Serializes the game state to a JSON object.
    JSONValue toJSON() {
        JSONValue j = ["ints": JSONValue(mIntMap), "floats": JSONValue(mFloatMap), "strings": JSONValue(mStringMap)];
        return j;
    }
}

/// Scene encapsulates the camera, tree, and game state for a level or UI screen.
struct Scene{
    SceneTree    mSceneTree;
    Camera 			 mCamera;
    GameState		 mGameState;
    SDL_Renderer* mRendererRef;
	IScript[]		mSceneScripts; 

    /// Create scene with a new camera.
    this(SDL_Renderer* r, string jsonDataFile, Camera cam){
        mRendererRef = r;
        mCamera = cam;
        mSceneTree = SceneTree(mRendererRef,5);

        // Load scene from json
        if (jsonDataFile.length > 0) {
            auto dataFile = File(jsonDataFile, "r");
            auto j = dataFile.byLine.joiner("\n").parseJSON;
            loadFromJSON(j);
        }
    }

    // Functions used to build scenes that were written to JSON.
    
    // void LoadCutscene() {
    //     mSceneTree.LoadWorldMenu();
    //     mSceneScripts ~= new CutsceneScript(&this);
    // }

    // void LoadWin() {
    //     mSceneTree.LoadWorldWinScreen();
    //     mSceneScripts ~= new WinScreenScript(&this);
    // }

    // void LoadLose() {
    //     mSceneTree.LoadWorldLoseScreen();
    //     mSceneScripts ~= new LoseScreenScript(&this);
    // }

    // void LoadMenu() {
    //     mSceneTree.LoadWorldMenu();
    //     mSceneScripts ~= new MenuScript(&this);
    // }

    // Forwards input handling to the scene tree.
    void Input() {
        mSceneTree.Input(mCamera);
    }

    /// Updates scripts and the scene tree.
    void Update() {
        foreach(ref s; mSceneScripts){
            s.Update();
        }
        mSceneTree.Update(mCamera);
    }

    /// Renders the scene tree.
    void Render() {
        mSceneTree.Render();
    }

    /// Loads the scene state from a JSON object.
    void loadFromJSON(JSONValue j) {
        mGameState.loadFromJSON(j["gameState"]);
        mSceneScripts = j["scripts"].array.map!(s => ScriptFactory.GetInstance().CreateScript(s.str, -1, &this)).array; // -1 for no owner?
        mSceneTree.loadFromJSON(j["sceneTree"]);
        // writeln("Finished Loading");
    }

    /// Serializes the scene into a JSON object.
    JSONValue toJSON() {
        JSONValue state = mGameState.toJSON();
        string[] scripts = mSceneScripts.array.map!(s => s.GetName()).array;
        JSONValue tree = mSceneTree.toJSON();

        JSONValue j = ["gameState": state];
        j.object["scripts"] = JSONValue(scripts);
        j.object["sceneTree"] = tree;
        return j;
    }
}

/// GameApplication encapsulates the main game loop, scenes, and rendering system.
struct GameApplication{

    Scene*[string] mScenes;
    string[string] mSceneJSONs;
    string   mActiveScene;

    bool mGameRunning=true;
    SDL_Renderer* mRenderer = null;

    /// Constructs a GameApplication, initializes SDL, audio, and loads the main scene.
    this(string title){
        SDL_Window* window= SDL_CreateWindow(title.toStringz,
                SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED,
                640,
                480, 
                SDL_WINDOW_SHOWN);
        // Create a hardware accelerated renderer
        mRenderer = SDL_CreateRenderer(window,-1,SDL_RENDERER_ACCELERATED);
        ResourceManager.GetInstance().SetRenderer(mRenderer);

        // mSceneJSONs["MainLevel"] = "testTile.json";
        // mSceneJSONs["win"] = "WinScene.json";
        // mSceneJSONs["gameOver"] = "LoseScene.json";
        // mSceneJSONs["Menu"] = "menu.json";
        // mSceneJSONs["Intro"] = "Intro.json";

        LoadFromJSON("gameApp.json");

        mScenes[mActiveScene] = new Scene(mRenderer, mSceneJSONs[mActiveScene],new Camera());

        // // Output scene JSON
        // JSONValue sceneJSON = mScenes[mActiveScene].toJSON();
        // writeln(sceneJSON.toPrettyString);
    }

    void LoadFromJSON(string jsonDataFile) {
        auto dataFile = File(jsonDataFile, "r");
        auto j = dataFile.byLine.joiner("\n").parseJSON;

        foreach(name, filename ; j["scenes"].object) {
            mSceneJSONs[name] = filename.str;
        }
        mActiveScene = j["active"].str;
    }

    /// Polls input events and forwards to the active scene.
    void Input() {
        mScenes[mActiveScene].Input();
        // (1) Handle Input
        SDL_Event event;
        // Start our event loop
        while(SDL_PollEvent(&event)){
            // Handle each specific event
            if(event.type == SDL_QUIT){
                mGameRunning= false;
            }
        }

    }

    /// Updates the current scene and handles scene transitions.
    void Update() {
        // writeln("Active scene:", mActiveScene);
        mScenes[mActiveScene].Update();
    }

    /// Clears the screen and renders the active scene.
    void Render() {
        SDL_SetRenderDrawColor(mRenderer,100,190,255,SDL_ALPHA_OPAQUE);
        SDL_RenderClear(mRenderer);
        
        mScenes[mActiveScene].Render();

        // Finally show what we've drawn
        // (i.e. anything where we have called SDL_RenderCopy will be in memory and presnted here)
        SDL_RenderPresent(mRenderer);
    }

    /// Processes a single frame of input, update, and render.
    void AdvanceFrame(){
        // writeln("=============Start Frame===============");
        Input();
        Update();
        if ("gameOver" in mScenes[mActiveScene].mGameState.mIntMap && mScenes[mActiveScene].mGameState.mIntMap["gameOver"] == 1) {
            mGameRunning = false;
            // writeln("GAME OVER");
        } else if ("nextScene" in mScenes[mActiveScene].mGameState.mStringMap) {
            // writeln("Switching scene to ", mScenes[mActiveScene].mGameState.mStringMap["nextScene"]);
            mActiveScene = mScenes[mActiveScene].mGameState.mStringMap["nextScene"];
            mScenes[mActiveScene] = new Scene(mRenderer, mSceneJSONs[mActiveScene], new Camera());
        } else {
            // Doesn't render if scene switched or game over
            Render();	
        }
        // writeln("--------------End Frame----------------");
    }

    /// Main game loop with frame capping logic.
    void RunLoop(){
        // CITATION: much of this code is adapted from the example code from lecture,
        // specifically Module 05 Slide 65, attributable to Michael Shah
        // https://docs.google.com/presentation/d/10rkYds8I9qbNXln840sbwnpucwa_u1EVt328yZro03Q/edit#slide=id.g328efb22a70_0_17

        // Initialize variables to help with framecapping
        auto previous = SDL_GetTicks();
        auto accumulatedTime = 0;
        auto framesCompleted = 0;
        int fps = 60;
        double targetFrameTime = 1000.0 / fps;

        while(mGameRunning){
            // Update variables to track frame time
            auto frameStart = SDL_GetTicks();       // get time at start of frame
            auto current = frameStart;              // current frame time (same as time when frame started)
            auto elapsed = frameStart - previous;   // elapsed time since last frame
            previous = current;	                    // update 'previous time'

			// Process next frame (which may take some varying amount of time)
            AdvanceFrame();

            // If not enough time has elapsed yet (bc frame rendered too fast) then delay
            auto total_time = SDL_GetTicks() - frameStart;  // includes processing time from AdvanceFrame()
            auto delay = targetFrameTime - total_time;
            if (delay > 0) {
                SDL_Delay((delay).to!uint);
            }

            accumulatedTime += SDL_GetTicks() - frameStart; // time right now minus time at which we started

            // For every '1' second of accumulated time, report number of completed frames
            if(accumulatedTime > 1000) {
                // string framerate = "Framerate is: " ~framesCompleted.to!string;
                // writeln(framerate);
                accumulatedTime = 0;
                framesCompleted = 0;
            }
			framesCompleted++;
        }
    }

}