import std.stdio;
import std.algorithm;

import linear;
import gameobject;
import component;
import scripts;
import std.math, std.string;

import bindbc.sdl;
import gameapplication;
import resourcemanager;


/// Script that runs logic for the scene, including player-enemy collision and transitions.
class GameScript : IScript{
        Scene *mScene;
        uint mStartTime;
        bool startMusic;
        
        /// Constructs a SceneScript associated with a given scene.
		this(Scene* scene) {
            mScene = scene;
            mScene.mGameState.mStringMap["state"] = "alive";
            mScene.mGameState.mIntMap["gameOver"] = 0;
            startMusic = true;
        }

		/// Updates the script logic every frame.
        /// Checks for collisions between the player and enemies after a delay,
        /// and triggers a death animation and scene transition.
        override void Update(){
            if (mScene.mGameState.mStringMap["state"] == "alive") {   
                // writeln("Running SceneScript");
                if (startMusic) {
                    // writeln("starting music...");
                    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)==-1){
                        writeln("Audio library not working: "~Mix_GetError().fromStringz);
                    }

                    // Start background music
                    Mix_Music* bgMusic = ResourceManager.GetInstance().LoadMusicResource("assets/music/sound_chase.wav");
                    if(Mix_PlayMusic(bgMusic, -1) == -1) {
                        writeln("There was an error playing the music: ");
                        writeln(Mix_GetError().fromStringz());
                    }

                    startMusic = false;
                }
                
                // Retrieve the game object
                GameObject player = GameObject.GetGameObject("MainPlayer");
                auto playerposition = cast(ComponentCollision)player.GetComponent(ComponentType.COLLISION);
                
                // Check if player won
                if (playerposition.mRect.x > 400) {
                    mScene.mGameState.mStringMap["nextScene"] = "win";
                    return;
                }

                foreach (ref obj ; mScene.mSceneTree.mGameObjects) {
                    if (obj.GetName().startsWith("Enemy")) {
                        auto collision = cast(ComponentCollision)obj.GetComponent(ComponentType.COLLISION);
                        if (playerposition.isColliding(collision.mRect))
                        {
                            auto animatedtex = cast(ComponentAnimatedTexture)player.GetComponent(ComponentType.ANIMATEDTEXTURE);
                            animatedtex.ChangeAnimationSequence("die");
                            mScene.mGameState.mStringMap["state"] = "dying";
                        }
                    }
                }
            } else if (mScene.mGameState.mStringMap["state"] == "dying") {
                GameObject player = GameObject.GetGameObject("MainPlayer");
                auto animatedtex = cast(ComponentAnimatedTexture)player.GetComponent(ComponentType.ANIMATEDTEXTURE);
                
                // writeln("Death animation complete. Switching to next scene...");
                mScene.mGameState.mStringMap["nextScene"] = "gameOver";
                
            }
		}

        /// Returns the name of this script.
		override string GetName() {
			return "GameScript";
		}

		private:
		size_t mOwner;
}