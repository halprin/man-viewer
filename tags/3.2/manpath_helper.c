//
//  manpath_helper.c
//  Man Viewer
//
//  This code is never compiled into the actual Man Viewer application.
//  It is a helper program to force the login shell to be interactive so we can get the real manpaths.
//
//  Created by Peter Kendall on 10/20/09.
//  Copyright 2009 @PAK Software. All rights reserved.
//

#include <unistd.h>

int main(int argc, char* argv[])
{
	execl(argv[1], "-", "-i", "-c", "/usr/bin/manpath", NULL);
	return 0;
}
