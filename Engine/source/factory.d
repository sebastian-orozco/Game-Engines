module factory;

import gameobject;
import component;
import script;
import gameapplication;
import linear;
import bindbc.sdl;

// Meta-programming to generate factories for creating game objects
// See: https://dlang.org/articles/variadic-function-templates.html
// CAUTION: Each new ordering of components will instantiate a new type.
// 					I'd thus recommend 'sorting' the variadic arguments. That takes
//          a little bit more work, and I'll leave as an exercise until someone asks..



/// Creates a GameObject with specified component types.
/// Params:
///     name = name of the game object
/// Returns: A new GameObject with the given components
GameObject GameObjectFactory(T...)(string name){
    // Create our game object
    GameObject go = new GameObject(name);
    // Static foreach loop will be 'unrolled' with
    // each 'if' condition for what is true.
    // This could also handle the case where we repeat component types as well if our
    // game object supports multiple components of the same type.
    static foreach(component ; T){
        static if(component == ComponentType.TEXTURE)
        {
            go.AddComponent!(component)(new ComponentTexture(go.GetID()));
        }
        static if(component == ComponentType.COLLISION){
            go.AddComponent!(component)(new ComponentCollision(go.GetID()));
        }
        static if(component == ComponentType.TRANSFORM){
            go.AddComponent!(component)(new ComponentTransform(go.GetID()));
        }
        static if(component == ComponentType.ANIMATEDTEXTURE){
            go.AddComponent!(component)(new ComponentAnimatedTexture(go.GetID()));
        }
    }
    return go;
}

// Example of an alias to make our GameObjectFactory a bit more clean.
alias MakeAnimatedSprite      = GameObjectFactory!(ComponentType.COLLISION,ComponentType.TEXTURE,ComponentType.TRANSFORM,ComponentType.ANIMATEDTEXTURE);
alias MakeSprite      = GameObjectFactory!(ComponentType.COLLISION,ComponentType.TEXTURE,ComponentType.TRANSFORM);
alias MakeBoundingBox =  GameObjectFactory!(ComponentType.COLLISION, ComponentType.TRANSFORM);
alias MakeCutscene = GameObjectFactory!(ComponentType.TEXTURE, ComponentType.TRANSFORM, ComponentType.ANIMATEDTEXTURE);
alias MakeBackdrop = GameObjectFactory!(ComponentType.TEXTURE, ComponentType.TRANSFORM);

/// Singleton factory for creating scripts dynamically.
struct ScriptFactory{
    static ScriptFactory* GetInstance(){
        if(mInstance is null){
            mInstance = new ScriptFactory();
        }
        return mInstance;
    }

    alias ScriptFactoryCallback = IScript delegate(size_t objOwner, Scene* sceneOwner);

    static RegisterScriptFactory(string type, ScriptFactoryCallback cb) {
        mFactoryRegistrar[type] = cb;
    }

    static CreateScript(string type, size_t oOwner, Scene* sOwner) {
        return mFactoryRegistrar[type](oOwner, sOwner);
    }

    ~this(){}

    private:
        static ScriptFactory* mInstance;
        static ScriptFactoryCallback[string] mFactoryRegistrar;
}

/// Singleton factory for creating components dynamically.
struct ComponentFactory{
    static ComponentFactory* GetInstance(){
        if(mInstance is null){
            mInstance = new ComponentFactory();
        }
        return mInstance;
    }

    alias ComponentFactoryCallback = IComponent delegate(size_t owner);

    static RegisterComponentFactory(string type, ComponentFactoryCallback cb) {
        mFactoryRegistrar[type] = cb;
    }

    static CreateComponent(string type, size_t owner) {
        return mFactoryRegistrar[type](owner);
    }

    ~this(){}

    private:
        static ComponentFactory* mInstance;
        static ComponentFactoryCallback[string] mFactoryRegistrar;
}

GameObject CreateTextLabel(string spriteName, string initialText, string fontPath, int fontSize, Vec2f position, SDL_Renderer* renderer)
{
    GameObject label = MakeSprite(spriteName);

    // Get components
    auto tex = cast(ComponentTexture) label.GetComponent(ComponentType.TEXTURE);
    auto transform = cast(ComponentTransform) label.GetComponent(ComponentType.TRANSFORM);

    // Add text component
    auto textComp = new ComponentText(label.GetID);
    label.AddComponent!(ComponentType.TEXT)(textComp);

    // Set transform and initial position
    transform.Translate(cast(int)position.x, cast(int)position.y);
    tex.SetDest(position, Vec2f(1, 1), 0);
    tex.mRenderer = renderer;

    // Set initial text on texture
    SDL_Color white = SDL_Color(255, 255, 255, 255);
    // tex.SetText(initialText, fontPath, white);  // Optional convenience wrapper

    // Approximate dimensions (or skip if SetDynamic handles it)
    tex.mRect.w = 150;
    tex.mRect.h = 30;

    // Setup ComponentText
    textComp.mTextureRef = &tex;
    textComp.mRenderer = renderer;
    textComp.SetFont(fontPath, fontSize, white);
    textComp.SetText(initialText);
    textComp.SetDynamic(true);
    textComp.UpdateTexture();

    return label;
}