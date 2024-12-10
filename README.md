# Assembly-Game
**DanceToTheVinyl**: An interactive game made with Motorola 68000 assembly language
The context of the game is that you play Michael Jackson; vinyl records fall from the top, some of which are genuine records while others are broken ones. Each time MJ catches a genuine record, he will start singing one of his popular/my favorite songs, and he'll also dance to the beats. You are responsible for controlling MJ, i.e., making him dodge the broken records and catch the genuine ones, all while the counter is going on, by the end of which you must collect 10 of MJ's songs. This game runs at 20 fps.

Video of gameplay: https://drive.google.com/file/d/1VM5agTEWF2JABMCG8tbehukb4tf8hjbg/view

Why I worked on this project:
I did this project in 3 weeks as part of my assembly course at Florida Interactive Entertainment Academy. The project was implemented on Eas68K, which is a simulator for 68000 made for educational purposes. I am grateful to Jeremy Paulding for mentoring me and teaching the core concepts of assembly programming. 

Technical challenges—
Nothing comes readymade with assembly, no libraries or frameworks. 
General Optimization: With the limitations of the simulator and the hardware I was testing on, to hit at least 20 fps, I needed to optimize the most expensive and frequent operations as much as possible. The most expensive and most frequent being putting a pixel on screen. The hardest part was optimizing the bitmap rendering.

Specific challenges: 

1. **Image rendering**: I made subroutines for loading bitmap files in memory and parsing through the contents of the file. The game required several BMPs to be loaded. During the loading stage of the game, all the bitmaps were loaded and parsed and stored in a way that would be highly efficient for reading pixel data and rendering. A BMP has several bytes of information in the header(s), and I didn't need every pixel's information from the pixel array. I needed to draw a cutout from the entire BMP. Also, the format for passing the r,g,b, and alpha data to the draw function in 68000 was a well-defined format that wasn't the same as how data was organized in the BMP. Doing these operations before making the draw call with the r,g,b, alpha, and location information data for each pixel in the game as a frame is being loaded would have taken a big hit on the FPS; most likely it would have made the game unplayable. Therefore, in the loading stage, I did all this precomputation in the loading stage and stored the necessary data in memory.
2. **Optimization**: With the aim of saving computational cycles, I explored the costs of various instructions and optimized as much as possible. Left shift once is equivalent to unsigned multiplication with 2; left shift twice is the same as unsigned multiplication with 4; similarly, right shift is equivalent to division by 2. Code can be refined in a way to reduce the number of conditional or unconditional branch instructions since each branch takes a significant number of cycles. Temporary variables can be stored on the stack or in registers. Accessing registers is faster. Operations can be byte, word, or long word sized, with growing order of time complexity. Some optimization is done by clubbing subtraction, multiplication, addition operations, and compare operations. Compare operations Perform the subtraction, update the status registers, but don't make changes to the operands, so if you are doing a subtraction first, you don't need to do a comparison later because subtraction itself will update the status registers. 68000 had some specialized instructions that made some tasks efficient, as I am sure each of the assembly languages has in their instruction sets, so I took the effort to read the manual and try some instructions that optimized my code further.
4. **Memory management**: The program has access to stack memory, code memory, and data memory, so it can store data of the objects in my game, such as the vinyl position, speed data, loaded bitmaps, file names, music file names, global variables, seven-segment symbol table, table of function pointers, and other kinds of things that need storage. I stored them in the program's data segment and bss (for uninitialized globals). Besides this, I implemented a memory manager to mimic the heap in higher-level programming languages. The memory manager has access to, say, 5 MB of space in the data segment. Its API has functions to allocate blocks of memory, free blocks, and coalesce multiple blocks and internally maintains these blocks. Each block has an 8-byte header that has this information: size of block, is block free, address of next block. So this memory manager was used for making some dynamic memory allocations.
5. **Game loop**: Starts with clearing previously drawn objects—only those whose positions can update this frame, so the vinyls that are falling and the character (MJ) that is moving around the stage need to be cleared, and background image data that was there needs to be redrawn. The next step is to run update logic on these objects, the vinyls and the character. Most likely they have new positions; MJ may even have a new image since he is animating in sync with the music. Check for collisions next; have any of the vinyls collided with MJ, i.e., do they intersect with the x and y bounds of MJ? Finally, call the draw function on all the objects. And before looping back, check how much time this frame took, and since the target is to have a consistent fps of 20, add a frame delay for the time differential.
6. **Object-oriented approach in assembly**: Just the way structs work in C/C++, which is variables of different data types are loaded one after another, the attributes of the objects were loaded. I had to give extra attention to padding when allocating memory since a word or long word-sized element cannot be accessed from an odd memory address, but a byte-sized allocation can be. Each vinyl object took up 16 bytes of memory: 2 bytes for x-pos, 2 bytes for y-pos, 4 bytes for time (a vinyl waits for 3/5 seconds before appearing again after crossing the bounds of the screen), 2 bytes for velocity, 4 bytes reserved spare, 1 byte for the type of vinyl—genuine or broken (as a vinyl (re)appears, it is randomized what type it would be; on the basis of the type, the associated bitmap is rendered)—and lastly, 1 byte for whether the vinyl is on screen. These 16-byte memory allocations for the vinyls were done contiguously, similar to an array, so to access, say, the 3rd vinyl object, I would need to go to the starting address of the allocation and move to the new address, which is the starting address + 16 bytes * 2. To then access the velocity of the vinyl, I offset by 8 bytes and load 2 bytes from the memory into a register or the stack.
7. **Physics**: The vinyls falling are accelerating downward to achieve acceleration. I used fixed-point math since there is no native support for floating-point numbers in assembly; it is all bits at the end of the day. With fixed-point math, based on the requirements of your application, you can choose a format that is most suitable, such as 8.8, 12.4, or 4.12, where the first 4 bits are whole number bits and the next 12 bits represent fractional bits. I restricted myself to 16 bits instead of 32 bits since multiplications in 68000 accepted word-sized (16-bit) operands only. I chose the 8.8 fixed point format and performed math to add the effect of gravity to the vinyl's position and velocity. If you left shift a value by 8 bits, the least significant 8 bits now represent the fractional value. I had the value of the gravitational constant pre-calculated in 8.8 format, which I added to the velocity now represented in 8.8. The position is also left-shifted by 8, and the updated velocity is added to the position; finally, the position is right-shifted by 8 to get the whole number representation again.
8. **Collision**: A collision can happen between a vinyl and the character. So on update of a vinyl, I always jump to subroutine IsColliding, where it checks some conditions. If vinyl right x < char left x or char right x < vinyl left x or vinyl lower y < char upper y or vinyl upper y > char lower y, then no collision is happening; otherwise, a collision is happening. In the subroutine OnCollision, the vinyl is _deactivated_, which basically removes it from the screen, and it reappears after some time. If the type of vinyl was genuine, the next music file is played; otherwise, if the type was broken, then the currently playing music is stopped. The game has a couple of 7-segment displays—one that displays the number of records left to catch and another that displays the time remaining. The display that shows the number of records left is updated.
10. **Dance Choreography**: A bunch of MJ dance moves images are loaded in the memory from a free spritesheet. Each dance move is loaded as separate image data, and they are loaded contiguously. A global variable, which is currentMovePointer, points to the current dance move that MJ is in. Similarly, another array is created that of walking moves, which will play when MJ is walking on stage instead of dancing. I have precalculated for each of MJ's songs what the rhythm is in beats per minute (bpm). Based on the rhythm and comparing current time with the last time the previous frame was rendered, the dance moves are changed in sync with the beats. The constraint with my code is that the songs have consistent BPM. In my subroutine AnimateCharacter, I check for the current time and current beat duration to check if the next move should be played. I also check if the character is walking currently, which is based on a global variable, isWalking, which is set in a different subroutine that checks if one of the arrow keys is pressed. In case isWalking is set, the next frame is picked from the walking moves array, and it is cycled through at a consistent frequency. If MJ is idle, the idle frame is rendered.
11. **7-segment displays**: There was no inbuilt support for displaying 7-segment displays. So for each of the 10 numbers 0 through 9, I determined what their bitmasks would be so that if I do _and_ with the 7 bits representing the 7 segments, I am able to get the necessary segments on. I had a 2-digit 7-segment display, so I had additional logic for determining the values to be displayed on the displays. So I divide the 2-digit number by 10; the resultant lower word contains the quotient, which goes in the first segment, and then the result is logically right-shifted twice by 8 to get the remainder, which is in the upper word. One of the input registers contains the x offsets; the upper word contains the right offset, and the lower word contains the left offset. This offset information is used to draw the segment. Implemented function pointers by making dedicated subroutines for displaying each segment a through f. I have a memory allocation of 7*4 = 28 bytes, where 4 bytes each hold the address of each of the subroutines of displaying a segment. This memory is labelled SevenSegmentFunctions, and using offsets of 4 bytes, it is used to jump to required draw subroutines for the segments.
12. **Sound**: I used the API provided by Easy68K, allowing me to use the DirectX player to load .wav files. I loaded 10 MJ songs into the DirectX player, and the order they have been loaded into the player is also the index that can be used to tell the DirectX player to play that particular song. So using a var CurrentSong = 0, I could increment it when needed and play the necessary song.



**Gameplay** : 
You have 60 seconds to collect 10 songs and make sure to dance sufficiently so that you entertain the crowd with MJ's charismatic dance and singing!

I am a huge huge Michael Jackson fan (as are millions of people even today), so when in my Game programming class Jeremy asked the each of us to take up a game idea and create a game design document of either an existing game or an original, I first thought of one of those standard mobile games where you have a basket and you must dodge the bombs while collecting the fruits. I reconciled that basic premise with my deep desire to make a Michael Jackson game. Throughtout the 3 weeks of development I listend to so much of MJ that it made the development process a thrilling journey! 
Three cheers for the King of Pop!

