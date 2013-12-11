/*
 *  メイン関数モジュール
 */
module dlife.main;

import sdl;

import std.stdio;

enum WINDOW_WIDTH = 640;
enum WINDOW_HEIGHT = 480;

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

    auto window = enforceSDL(SDL_CreateWindow(
                args[0].ptr, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN));
    scope(exit) SDL_DestroyWindow(window);

    SDL_Delay(10000);
}

