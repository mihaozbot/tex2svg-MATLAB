# tex2svg-MATLAB

Converts LaTeX equations to SVG format using Inkscape coded in MATLAB.

## Requirements
- MATLAB 2022b or later
- Inkscape (installed and accessible from the command line)
- pdflatex (installed and accessible from the command line)
- LaTeX packages: amsmath, amsfonts

## Arguments
- `tex_file`: (optional) Path to the LaTeX file. If not provided, the function will search for .tex files in the current folder.
- `output_folder`: (optional) Output folder to save the SVG files. If not provided, the function will create an output folder with the same name as the input tex_file.

## Usage

```
tex2svg()  % Converts all .tex files in the current folder
tex2svg(tex_file)  % Converts equations in the specified tex_file
tex2svg(tex_file, output_folder)  % Specify the output folder for SVG files
```

## Notes
The function relies on regular expressions to find equations in the LaTeX file. It assumes a specific format for the equations, i.e., they should be enclosed in \begin{equation} and \end{equation} tags.
The function uses the pdflatex command to compile the equations to PDF files and then uses Inkscape to convert the PDF files to SVG.
Ensure that Inkscape and pdflatex are installed and accessible from the command line for the conversion to work properly.

## Example
This example will convert equations in 'equations.tex' to SVG format and save the SVG files in the 'svg_output' folder.
```
tex_file = 'paper.tex';
output_folder = 'output_folder';
tex2svg(tex_file, output_folder);
```
If no arguments are provided, the function will convert all .tex files in the current folder.
```
tex2svg()
```
