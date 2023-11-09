#!/usr/bin/octave -q
close all
clear
clc

fs = 48000;

addpath('~/playrec');

pagesize = 256
pagebufferlength = 2;

process([], fs, pagesize, pagesize*2, 1024);

if playrec('isInitialised')
  playrec('reset')
  sleep(0.1);
end

if ~playrec('isInitialised')
  playrec('init', fs, 0, 0, 2, 2);
  pause(0.1);
end

in = zeros(pagesize,2);
out = zeros(pagesize,2);

assert(playrec('isInitialised'));

if playrec('pause')
  playrec('pause', 0);
end

playrec('delPage');

pagelist = zeros(pagebufferlength,1);
for i=1:pagebufferlength
  pagelist(i) = playrec('playrec',out,[1 2],pagesize,[1 2]);
end

pagebufferidx = 1;
while true;
  playrec('block', pagelist(pagebufferidx));
%  tic;
  in = playrec('getRec', pagelist(pagebufferidx));
  playrec('delPage', pagelist(pagebufferidx));
  out = process(in);
  pagelist(pagebufferidx) = playrec('playrec',out,[1 2],pagesize,[1 2]);
  pagebufferidx = pagebufferidx + 1;
  if pagebufferidx > pagebufferlength
    pagebufferidx = 1;
  end
%  printf('rtf=%.3f\n',toc/(pagesize/fs));
end
