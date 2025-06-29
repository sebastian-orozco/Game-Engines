import std.stdio;

import linear;
import gameobject;
import component;
import scripts;
import std.math;

import bindbc.sdl;

/// Script that controls the main player's movement and animation based on keyboard input.
/// Handles collision with world boundaries and updates transform and animation state.
class PlayerScript : IScript{

		Vec2f mVel;

		/// Constructs a PlayerScript tied to a GameObject by ID.
		this(size_t owner){
			mOwner = owner;

			GameObject go = GameObject.GetGameObject(mOwner);
			auto position = cast(ComponentCollision)go.GetComponent(ComponentType.COLLISION);
			auto transform = cast(ComponentTransform)go.GetComponent(ComponentType.TRANSFORM);
			if(position !is null){
				// writeln(obj.GetName()," - collision render");
				Vec2f pos = transform.mWorldMatrix.Frommat3GetTranslation();
				position.mRect.x = cast(int)pos.x;
				position.mRect.y = cast(int)pos.y;
			}
		}

		/// Updates the player's movement based on keyboard input.	
    	/// Applies animation changes and restricts movement to within map bounds.
		override void Update(){
				//writeln("Running PlayerScript");
				// Retrieve the game object
				GameObject go = GameObject.GetGameObject(mOwner);
				auto position = cast(ComponentCollision)go.GetComponent(ComponentType.COLLISION);
				auto transform = cast(ComponentTransform)go.GetComponent(ComponentType.TRANSFORM);
				auto animatedtex = cast(ComponentAnimatedTexture)go.GetComponent(ComponentType.ANIMATEDTEXTURE);

				// Get Keyboard input
				const ubyte* keyboard = SDL_GetKeyboardState(null);

				mVel = Vec2f(0,0);

				// Check for movement
				if(keyboard[SDL_SCANCODE_LEFT]){ 
					mVel.x = -1;
					animatedtex.ChangeAnimationSequence("run");
				}
				if(keyboard[SDL_SCANCODE_RIGHT]){
					mVel.x = 1;
					animatedtex.ChangeAnimationSequence("run");
				}
				if(keyboard[SDL_SCANCODE_UP] ){
					mVel.y = -1;
					animatedtex.ChangeAnimationSequence("run");
				}
				if(keyboard[SDL_SCANCODE_DOWN]){
					mVel.y = 1;
					animatedtex.ChangeAnimationSequence("run");
				}

				// normalization
				float len = sqrt(mVel.x * mVel.x + mVel.y * mVel.y);
				if (len > 0.0f) {
					mVel.x /= len;
					mVel.y /= len;
				}
				
				//speed up
				mVel.x *= 4;
				mVel.y *= 4;

				if (mVel == Vec2f(0, 0)) {
				    animatedtex.ChangeAnimationSequence("idle");
				}

				// Get the world bounds from the "world" GameObject's collision box
				GameObject carpet = GameObject.GetGameObject("carpet");
				auto bounds = cast(ComponentCollision)carpet.GetComponent(ComponentType.COLLISION);
				int bounds_x = bounds.mRect.x;
				int bounds_y = bounds.mRect.y;
				int bounds_w = bounds.mRect.w;
				int bounds_h = bounds.mRect.h;
				int position_x = position.mRect.x;
				int position_y = position.mRect.y;
				int position_w = position.mRect.w;
				int position_h = position.mRect.h;

    			// Prevent the player from accelerating past the world edges
				// Get player object dimensions

    			// If player is at the left or right edge and accelerating further, stop this direction of movement
				if (position_x <= bounds_x && mVel.x < 0) {
					mVel.x = 0;
				}
				if (((position_x + position_w) >= (bounds_x + bounds_w)) && mVel.x > 0) {
					mVel.x = 0;
				}

				// If player is at the top or bottom edge and accelerating further, stop this direction of movement
				if (position_y <= bounds_y && mVel.y < 0) {
					mVel.y = 0;
				}
				if (((position_y + position_h + 10) >= (bounds_y + bounds_h)) && mVel.y > 0) {
					mVel.y = 0;
				}

				// Perform acceleration
				transform.Translate(mVel.x,mVel.y);
				if(position !is null){
					// writeln(obj.GetName()," - collision render");
					Vec2f pos = transform.mWorldMatrix.Frommat3GetTranslation();
					position.mRect.x = cast(int)pos.x;
					position.mRect.y = cast(int)pos.y;
				}

		}

		/// Returns the name of this script.
		override string GetName() {
			return "PlayerScript";
		}

		private:
		size_t mOwner;
}