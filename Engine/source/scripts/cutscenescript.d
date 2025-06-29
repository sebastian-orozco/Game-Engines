import std.stdio;

import linear;
import gameobject;
import component;
import scripts;
import std.math, std.string;

import bindbc.sdl;
import gameapplication;
import resourcemanager;

/// Script that controls the logic for a cutscene GameObject.
/// Marks the scene as complete when the animation reaches the last frame.
class CutsceneScript : IScript{
        Scene* mScene;
		bool startMusic;
        
        /// Constructs a CutsceneScript tied to a GameObject by ID.
        /// Records the initial time the script starts.
		this(Scene* scene) {
			mScene = scene;
			startMusic = true;
        }

		/// Updates the cutscene logic each frame.
        /// When the current animation finishes, flags the scene as complete.
		override void Update(){
			if (startMusic) {
                // writeln("starting music...");
                if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)==-1){
                    writeln("Audio library not working: "~Mix_GetError().fromStringz);
                }
                // Start background music
                Mix_Music* bgMusic = ResourceManager.GetInstance().LoadMusicResource("assets/music/cutscene_audio.wav");
                if(Mix_PlayMusic(bgMusic, -1) == -1) {
                    writeln("There was an error playing the music: ");
                    writeln(Mix_GetError().fromStringz());
                }
                startMusic = false;
            }

            GameObject go = GameObject.GetGameObject("intro_cutscene");
        	auto animatedtex = cast(ComponentAnimatedTexture)go.GetComponent(ComponentType.ANIMATEDTEXTURE);
            if (animatedtex.mCurrentFramePlaying == animatedtex.mLastFrameInSequence) {
                mScene.mGameState.mStringMap["nextScene"] = "Menu"; // Make this variable?
            }
		}

        // Returns the name of this script.
		override string GetName() {
			return "CutsceneScript";
		}

		private:
		size_t mOwner;
}