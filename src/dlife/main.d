/*
 *  メイン関数モジュール
 */
module dlife.main;

import sdl;

import std.stdio;

/**
 *  メイン関数
 *
 *  Params:
 *      args = コマンドライン引数
 */
void main(string[] args) {
    // SDL初期化。最後に終了。
    enforceSDL(SDL_Init(SDL_INIT_EVERYTHING));
    scope(exit) SDL_Quit();
}

