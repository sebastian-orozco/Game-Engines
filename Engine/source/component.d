// @file: full_component/component.d
import std.stdio, std.conv, std.json;

import linear;
import resourcemanager;

import bindbc.sdl;

import std.algorithm, std.conv, std.json, std.array;

import gameobject;
import resourcemanager;

/// Types of components supported in the engine.
enum ComponentType{TEXTURE,ANIMATEDTEXTURE,COLLISION,TRANSFORM,TEXT};//AI,SCRIPT};

/// Interface for all components in the engine.
interface IComponent{
	/// Updates the component every frame.
	void Update();
	/// Renders the component to the screen.
	void Render(SDL_Renderer* r);
	/// Loads component data from a JSON object.
	void loadFromJSON(JSONValue j);
	/// Serializes the component to JSON.
	JSONValue toJSON();
	/// Returns the name/type of the component.
	string GetName();
}

/// A texture-rendering component that supports scaling, rotation, and optional text rendering.
class ComponentTexture : IComponent{
    SDL_Texture* mTexture;
	string mFilename;
	// alias mTexture this;
    SDL_Renderer* mRenderer;
    double mAngle;
    bool mOwnsTexture;
	SDL_Rect mRect;
	Vec2f destScale;
	SDL_Rect mSrcRect;

	this(size_t owner){
		mOwner = owner;
		mAngle = 0;
	}

	/// Sets the texture from a file and optional source rectangle.
	bool SetTexture(string filename, SDL_Rect srcRect=SDL_Rect(0,0,0,0)){
		if (filename !is null) {
            mTexture = ResourceManager.GetInstance().LoadImageResource(filename);
			if (mTexture is null){
				return false;
			}
        } else {
            return false;
        }
		mFilename = filename;
        mOwnsTexture = false;
		mSrcRect = srcRect;
		return true;
	}

	/// Sets the destination position, scale, and angle.
	void SetDest(Vec2f pos, Vec2f scale, double angle){
		mRect.x = to!int(pos.x);
		mRect.y = to!int(pos.y);
		destScale = scale;
		mAngle = angle;
	}

	/// Sets the texture from rendered text.
    // void SetText(string text, TTF_Font* font, SDL_Color color) {
	// 	import std.string;
    //     SDL_Surface* surface = TTF_RenderText_Solid(font, text.toStringz, color);
    //     mTexture = SDL_CreateTextureFromSurface(mRenderer, surface);
    //     SDL_FreeSurface(surface);
    //     mOwnsTexture = true;
    // }

	/// Sets the rotation angle in degrees.
    void SetRotation(double angle) {
        mAngle = angle;
    }

	/// Rotates the texture by a given angle.
    void turn(double angle) {
        mAngle = (mAngle + angle)%360;
    }

    ~this(){
        // if (mOwnsTexture) {
    	// SDL_DestroyTexture(mTexture);
        // }
    }

	override void Update(){
		// Note: The 'cast' is so I can get the address and verify we
		//       have different components
		// writeln("\tUpdating Texture: ",cast(void*)this);
	}

	override void Render(SDL_Renderer* r) {
		if (mTexture !is null){
			SDL_Rect dest = mRect;
			dest.w = to!int(mRect.w * destScale.x);
			dest.h = to!int(mRect.h * destScale.y);

			if (mSrcRect == SDL_Rect(0,0,0,0)) {
        		SDL_RenderCopyEx(r, mTexture, null, &dest, mAngle, null, SDL_FLIP_NONE);
			} else {
				SDL_RenderCopyEx(r, mTexture, &mSrcRect, &dest, mAngle, null, SDL_FLIP_NONE);
			}
		}
    }

	override void loadFromJSON(JSONValue j) {
		if ("filename" in j) {
			SetTexture(j["filename"].str);
		}
		SetRotation(j["angle"].floating);
		int[4] rect = j["rect"].array.map!(x => to!int(x.integer)).array;
		mRect = SDL_Rect(rect[0], rect[1], rect[2], rect[3]);
		destScale.x = to!int(j["destScale"].array[0].floating);
		destScale.y = to!int(j["destScale"].array[1].floating);
		int[4] srcRect = j["srcRect"].array.map!(x => to!int(x.integer)).array;
		mSrcRect = SDL_Rect(srcRect[0], srcRect[1], srcRect[2], srcRect[3]);
	}

	override JSONValue toJSON() {
		JSONValue j = ["angle": mAngle];
		if (mFilename.length > 0) {
			j.object["filename"] = mFilename;
		}
		j.object["rect"] = JSONValue([mRect.x, mRect.y, mRect.w, mRect.h]);
		j.object["destScale"] = JSONValue([destScale.x, destScale.y]);
		j.object["srcRect"] = JSONValue([mSrcRect.x, mSrcRect.y, mSrcRect.w, mSrcRect.h]);
		return j;
	}

	override string GetName() {
		return "TEXTURE";
	}

	private:
	size_t mOwner;
}

/// A component that manages axis-aligned bounding boxes and collision detection.
class ComponentCollision : IComponent{
	this(size_t owner){
		mOwner = owner;

		mRect = SDL_Rect(40,40,40,40);
	}
	~this(){}
	override void Update(){
		// Note: The 'cast' is so I can get the address and verify we
		//       have different components
		// writeln("\tUpdating Collision: ",cast(void*)this);
	}
	override void Render(SDL_Renderer* r){
		//writeln("Rendering collision at:", mRect);
		SDL_SetRenderDrawColor(r,0,255,255,SDL_ALPHA_OPAQUE);
		SDL_RenderDrawRect(r,&mRect);
	}

	 /// Sets the rectangle directly.
	void SetRect (int x, int y, int w, int h) {
		mRect.x = x;
		mRect.y = y;
		mRect.w = w;
		mRect.h = h;
	}

	/// Sets the world position of the collision box.
    void SetPosition (int x, int y) {
		mRect.x = x+offset_x;
		mRect.y = y+offset_y;
	}

	/// Sets the offset from the GameObject position.
    void SetOffset (int x, int y) {
		offset_x = x;
		offset_y = y;
	}

	/// Returns true if this component is colliding with another SDL_Rect.
	bool isColliding(SDL_Rect object) {
		return cast(bool) SDL_HasIntersection(&mRect, &object);
	}
  
	override void loadFromJSON(JSONValue j) {
		int[4] rect = j["rect"].array.map!(x => to!int(x.integer)).array;
		mRect = SDL_Rect(rect[0], rect[1], rect[2], rect[3]);
		offset_x = to!int(j["xOffset"].integer);
		offset_y = to!int(j["yOffset"].integer);
	}

	override JSONValue toJSON() {
		JSONValue j = ["xOffset": offset_x, "yOffset": offset_y];
		j.object["rect"] = JSONValue([mRect.x, mRect.y, mRect.w, mRect.h]);
		return j;
	}

	override string GetName() {
		return "COLLISION";
	}

	SDL_Rect mRect;	
	int offset_x;
    int offset_y;
	private:
	size_t mOwner;
}

/// A transformation component supporting translation, scaling, and rotation via 3x3 matrices.
class ComponentTransform : IComponent{
	this(size_t owner){
		mOwner = owner;
	}
	~this(){}
	override void Update(){
		// Note: The 'cast' is so I can get the address and verify we
		//       have different components
		//writeln("\tUpdating Transform: ",cast(void*)this);
	}
	override void Render(SDL_Renderer* r){
	}

	override void loadFromJSON(JSONValue j) {
		JSONValue localObj = j["local"].array;
		JSONValue worldObj = j["world"].array;
		float[3][3] localMat;
		float[3][3] worldMat;
		foreach(row ; 0..3) {
			localMat[row] = localObj[row].array.map!(x => to!float(x.floating)).array;
			worldMat[row] = worldObj[row].array.map!(x => to!float(x.floating)).array;
		}
		mLocalMatrix.e = localMat;
		mWorldMatrix.e = worldMat;
	}

	override JSONValue toJSON() {
		JSONValue j = ["local": JSONValue(mLocalMatrix.e), "world": JSONValue(mWorldMatrix.e)];
		return j;
	}

    /// Applies a translation to the local matrix.
    void Translate(float x,float y){
        mLocalMatrix = mLocalMatrix * mLocalMatrix.Translate(x,y);
    }

    /// Applies scaling to the local matrix.
    void Scale(float x,float y){
        mLocalMatrix = mLocalMatrix * mLocalMatrix.Scale(x,y);
    }
    
	/// Applies a rotation to the local matrix.
    void Rotate(float angle){
        mLocalMatrix = mLocalMatrix * mLocalMatrix.Rotate(angle);
    }

	/// Returns the object's world position.
    Vec2f GetPosition(){
        return mLocalMatrix.Frommat3GetTranslation();
    }

	/// Returns the object's scale.
    Vec2f GetScale(){
        return mLocalMatrix.Frommat3GetScale();
    }

	/// Returns the object's rotation angle.
    float GetAngle(){
        return mLocalMatrix.Frommat3GetRotation();
    }

	override string GetName() {
		return "TRANSFORM";
	}

    mat3 mLocalMatrix;
    mat3 mWorldMatrix;

	private:
	size_t mOwner;
}

/// A component for managing sprite animations using a texture atlas and metadata.
class ComponentAnimatedTexture : IComponent{
    /// Store an individual Frame for an animation
    struct Frame{
            SDL_Rect mRect;
            float mElapsedTime;
    }

	// SDL_Rect mRect;
    // Store filename of the data file for these sequences
    string mFilename;
    // Collection of all of the possible frames that are part of a sprite
    // At a minimum, these are just rectangles
    Frame[] mFrames;
    // Array of longs for the named sequence of an animation
    // i.e. this is a map, with a name (e.g. 'walkUp') followed by frame numbers (e.g. [0,1,2,3] )
    long[][string] mFrameNumbers;

	// Helpers for references to data
    SDL_Renderer* mRendererRef;
    ComponentTexture mTextureRef;
    ComponentTransform mTransformRef;
	

    // Stateful information about the current animation
    // sequene that is playing
    string mCurrentAnimationName; // Which animation is currently playing
    long mCurrentFramePlaying ;   // Current frame that is playing, an index into 'mFrames'
    long mLastFrameInSequence;

    /// Hold a copy of the texture that is referenced
    this(size_t owner){
		mOwner = owner;
    }
	~this(){}

	/// Loads metadata and connects to associated texture/transform components.
	bool SetTexture(string filename){
		if (filename !is null) {
            mTextureRef = cast(ComponentTexture) GameObject.GetGameObject(mOwner).GetComponent(ComponentType.TEXTURE);
			mTransformRef = cast(ComponentTransform) GameObject.GetGameObject(mOwner).GetComponent(ComponentType.TRANSFORM);
			if (mTextureRef is null || mTransformRef is null){
				return false;
			}
        } else {
            return false;
        }

		mFilename = filename;
		LoadMetaData(filename);
		return true;
	}

	override void Update(){
		// Note: The 'cast' is so I can get the address and verify we
		//       have different components
		// writeln("\tUpdating AnimatedTexture: ",cast(void*)this);
	}	

    /// Load a data file that describes meta-data about animations stored in a single file.
		/// In practice, this could be a public member function, so you can otherwise
		/// load new meta data as needed.
    void LoadMetaData(string filename){
      
        auto myFile = File(filename, "r");
        auto jsonFileContents = myFile.byLine.joiner("\n");
        auto j = parseJSON(jsonFileContents);

        auto format = j["format"].object;
        auto width = to!int(format["width"].integer);
        auto height = to!int(format["height"].integer);
        auto tileWidth = to!int(format["tileWidth"].integer);
        auto tileHeight = to!int(format["tileHeight"].integer);
        auto frames = j["frames"].object;
        mFrames.length = (width / tileWidth) * (height / tileHeight);

        foreach(animationName, frameIndices; frames){
            auto intFrameIndices = frameIndices.array.map!(x => x.integer).array;
            mFrameNumbers[animationName] = intFrameIndices;

            foreach(frameIndex; intFrameIndices){

                int row = cast(int) frameIndex / (width / tileWidth);
                int col = cast(int) frameIndex % (width / tileWidth);

                SDL_Rect rect = SDL_Rect(col*tileWidth, row*tileHeight.to!int, tileWidth, tileHeight);
                Frame newFrame;
                newFrame.mRect = rect;
                newFrame.mElapsedTime = 0.0f;
                mFrames[frameIndex] = newFrame;
        	}
      	}
    }

	/// Switches to a new animation sequence by name.
	void ChangeAnimationSequence(string name){
		if (mCurrentAnimationName != name){
            // If it's a new animation, start from the first frame
            mCurrentAnimationName = name;
            mCurrentFramePlaying = 0;
            mLastFrameInSequence = mFrameNumbers[name].length - 1;
        }
	}

    /// Play an animation based on the name of the animation sequence
    /// specified in the data file.
    override void Render(SDL_Renderer* r){
        auto currentFrameIndex = mFrameNumbers[mCurrentAnimationName][mCurrentFramePlaying];
        Frame currentFrame = mFrames[currentFrameIndex];
        currentFrame.mElapsedTime += 0.016f; // 60 FPS

        if (currentFrame.mElapsedTime >= 0.05){ // 50ms per frame
            mCurrentFramePlaying++; 
          
            if (mCurrentFramePlaying > mLastFrameInSequence){
                mCurrentFramePlaying = 0; // Loop back to the first frame
            }

            // Reset the elapsed time
            currentFrame.mElapsedTime = 0.0f;
        }

        mFrames[currentFrameIndex] = currentFrame;

		mTextureRef.mSrcRect = currentFrame.mRect;
		mTextureRef.Render(r);
    }

	override void loadFromJSON(JSONValue j) {
		mFilename = j["filename"].str;
		if ("currAnimation" in j) {
			mCurrentAnimationName = j["currAnimation"].str;
			mCurrentFramePlaying = j["currFrame"].integer;
			mLastFrameInSequence = j["lastFrame"].integer;
		}
	}

	override JSONValue toJSON() {
		JSONValue j = ["filename": mFilename];
		if (mCurrentAnimationName.length > 0) {
			j.object["currAnimation"] = mCurrentAnimationName;
			j.object["currFrame"] = mCurrentFramePlaying;
			j.object["lastFrame"] = mLastFrameInSequence;
		}
		return j;
	}

	override string GetName() {
		return "ANIMATEDTEXTURE";
	}

	private:
	size_t mOwner;
}

class ComponentText : IComponent{
	string mText;
	// Store font and font params
	TTF_Font* mFont;
	string mFontFile;
	int mFontSize;
	SDL_Color mColor;

	// Store resulting texture and texture component to "send" it to
	SDL_Texture* mTexture;
	ComponentTexture* mTextureRef;
	SDL_Renderer* mRenderer;

	// Optionally make texture size adapt to text
	bool mDynamicallySized;

	this(size_t owner){
		mOwner = owner;
		mDynamicallySized = false;
	}

	void UpdateTexture() {
		// writeln("Updating texture!");
		import std.string;
		if (mRenderer is null) {
			writeln("Text component renderer was not set");
			return;
		}
		if (mFont !is null) {
			if (mDynamicallySized && mTextureRef !is null) {
				int newW, newH;
				TTF_SizeText(mFont, mText.toStringz, &newW, &newH);
				mTextureRef.mRect.w = newW;
				mTextureRef.mRect.h = newH;
				// writeln("New size: ", mTextureRef.mRect);
			}
			SDL_Surface* surface = TTF_RenderText_Solid(mFont, mText.toStringz, mColor);
			if (surface is null) {
				writeln("There was an issue creating the text surface: "~SDL_GetError().fromStringz);
				return;
			}
			mTexture = SDL_CreateTextureFromSurface(mRenderer, surface);
			SDL_FreeSurface(surface);
			if (mTexture is null) {
				writeln("There was an issue creating the text texture from surface: "~SDL_GetError().fromStringz);
				return;
			}
			if (mTextureRef !is null) {
				mTextureRef.mTexture = mTexture;
			}
		} else {
			writeln("Font was not set before SetTexture");
		}
	}

    void SetText(string text) {
		if (text != mText) {
			mText = text;
			if (mFont !is null) {
				UpdateTexture();
			}
		}
    }

	void SetFont(string fontFile, int fontSize, SDL_Color color) {
		import std.string;
		mFontFile = fontFile;
		mFontSize = fontSize;
		mColor = color;
		mFont = TTF_OpenFont(fontFile.toStringz, fontSize);
		if (mText.length > 0) {
			UpdateTexture();
		}
	}

	void SetDynamic(bool isDynamic) {
		mDynamicallySized = isDynamic;
		UpdateTexture();
	}

    ~this(){
    	SDL_DestroyTexture(mTexture);
    }

	override void Update(){ 
	}

	override void Render(SDL_Renderer* r) { 
    }

	override void loadFromJSON(JSONValue j) {
		mFontFile = j["fontFile"].str;
		mFontSize = to!int(j["size"].integer);
		ubyte[] color = j["color"].array.map!(x => to!ubyte(x.integer)).array;
		mColor = SDL_Color(color[0], color[1], color[2]);
		if (color.length == 4) {
			mColor.a = color[3];
		}

		mText = ""; // Make sure set font does not try to update the texture
		SetFont(mFontFile, mFontSize, SDL_Color(255, 255, 255, 255));

		mText = j["text"].str;
		mDynamicallySized = j["dynamic"].boolean;
	}

	override JSONValue toJSON() {
		JSONValue j = ["text": mText, "fontFile": mFontFile];
		j.object["size"] = mFontSize;
		j.object["color"] = [mColor.r, mColor.g, mColor.b, mColor.a];
		j.object["dynamic"] = mDynamicallySized;
		return j;
	}

	override string GetName() {
		return "TEXT";
	}

	private:
	size_t mOwner;
}