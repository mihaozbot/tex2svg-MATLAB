function tex2svg(tex_file, output_folder)
% Converts LaTeX equations in a tex_file to SVG format using Inkscape.
%
% Author: Miha Ožbot
% Date:  17 June 2023
%
% Arguments:
%   - tex_file: (optional) Path to the LaTeX file. If not provided, the
%               function will search for .tex files in the current folder.
%   - output_folder: (optional) Output folder to save the SVG files. If not
%                    provided, the function will create an output folder
%                    with the same name as the input tex_file.
%
% Usage:
%   tex2svg()  % Converts all .tex files in the current folder
%   tex2svg(tex_file)  % Converts equations in the specified tex_file
%   tex2svg(tex_file, output_folder)  % Specify the output folder for SVG files
%
% Notes:
%   - Inkscape and pdflatex need to be installed and accessible from the
%     command line for the conversion to work.
%   - The function relies on regular expressions to find equations in the
%     LaTeX file. It assumes a specific format for the equations, i.e., they
%     should be enclosed in \begin{equation} and \end{equation} tags.
%   - The function uses the 'pdflatex' command to compile the equations to
%     PDF files and then uses Inkscape to convert the PDF files to SVG.
%   - Make sure to have the necessary LaTeX packages (amsmath, amsfonts)
%     installed for the equations in your LaTeX file.
%
% Example:
%   tex_file = 'equations.tex';
%   output_folder = 'svg_output';
%   tex2svg(tex_file, output_folder);
%
%   This example will convert equations in 'equations.tex' to SVG format and
%   save the SVG files in the 'svg_output' folder.
%

% Find all .tex files in the current folder if the input file is not provided
if nargin < 1 || isempty(tex_file)
    tex_files = dir('*.tex');
    tex_files = {tex_files.name};
else
    tex_files = {tex_file};
end

% Iterate over each .tex file
for i = 1:numel(tex_files)
    tex_file = tex_files{i};


    equations = find_equations(tex_file);

    % Read the original tex file to find newcommand lines
    file_content = fileread(tex_file);
    newcommands = regexp(file_content, '\\newcommand.*?\n', 'match');

    % Create the output directory
    if nargin < 2 || isempty(output_folder)
        [~, output_dir, ~] = fileparts(tex_file);
    else
        output_dir = output_folder;
    end

    fclose('all');  % Close all open file handles

    % Create a log file
    log_file = fullfile(output_dir, 'tex2svg_log.txt');
    diary(log_file);

    % Get the current date and time
    current_datetime = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    % Display the log file information with date and time
    disp('');
    disp(['Logging all displays to: ', log_file]);
    disp(['Log started at: ', current_datetime]);
    disp('');  % Add a new line at the beginning
    fprintf('Processing input file: %s\n', tex_file);

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    fprintf('Output directory: %s\n', output_dir);
    [status, result] = system('pdflatex --version');

    if status == 0
        fprintf('pdflatex is working. \n %s\n', result);
    else
        fprintf('Failed to run pdflatex. Error: %s\n', result);
    end

    % Save each equation in a separate .tex file and compile to PDF
    for j = 1:numel(equations)
        equation = equations{j};
        equation_file = create_equation_file(equation, output_dir, j, newcommands);
        equation_basename = compile_equation(equation_file);
    end

    inkscape_path = 'inkscape'; % Change this to the correct path if necessary

    [status, cmdout] = system([inkscape_path, ' --version']);
    if status == 0
        disp("Inkscape executable is working. Output: " + cmdout);
    else
        inkscape_path = 'C:\Program Files\Inkscape\bin\inkscape.exe';
        disp('The "inkscape" command is not available in the system path.')
        disp(['Fallback to absolute path: ', '"',inkscape_path,'"']);
    end

    if exist(inkscape_path, 'file')
        disp('Inkscape executable found.');
    else
        disp('Inkscape executable not found at the specified path.');
    end

    try
        [~, cmdout] = system(['"',inkscape_path,'"', ' --version']);
        disp("Inkscape executable is working. Output: " + cmdout);
    catch
        disp("Failed to run Inkscape. Please provide the correct path to the Inkscape executable.");
    end

    files = dir(output_dir);
    for k = 1:numel(files)
        file_name = files(k).name;
        if endsWith(file_name, '.pdf')
            pdf_file = fullfile(output_dir, file_name);
            svg_file = fullfile(output_dir, [file_name(1:end-4), '.svg']);
            convert_pdf_to_svg(pdf_file, svg_file, inkscape_path);
            fprintf('Output SVG file: %s\n', svg_file);
        end
    end
end
% Display end of program
disp('Program completed successfully.');

% Close the log file
diary off;

end

function equations = find_equations(tex_file)
file_content = fileread(tex_file);
equations = regexp(file_content, '\\begin{equation}(.*?)\\end{equation}', 'tokens', 'lineanchors');
equations = cellfun(@(x) x{1}, equations, 'UniformOutput', false);
end

function equation_file = create_equation_file(equation, output_dir, equation_index, newcommands)
equation_content = sprintf('\\documentclass[preview,varwidth]{standalone}\n');
equation_content = [equation_content, sprintf('\\usepackage{amsmath,amsfonts}\n')];
equation_content = [equation_content, sprintf('\\usepackage[noabbrev]{cleveref}\n')];

for i = 1:numel(newcommands)
    equation_content = [equation_content, sprintf('%s\n', strtrim(newcommands{i}))];
end

equation_content = [equation_content, sprintf('\\begin{document}\n')];

if ~contains(equation, '\begin{')
    equation_content = [equation_content, sprintf('\\(\n')];
    equation_content = [equation_content, sprintf('%s\n', strtrim(equation))];
    equation_content = [equation_content, sprintf('\\notag\n')];
    equation_content = [equation_content, sprintf('\\)\n')];
else
    equation_content = [equation_content, sprintf('\\begin{equation}\n')];
    equation_content = [equation_content, sprintf('%s\n', strtrim(equation))];
    equation_content = [equation_content, sprintf('\\notag\n')];
    equation_content = [equation_content, sprintf('\\end{equation}\n')];
end

equation_content = [equation_content, sprintf('\\end{document}\n')];

equation_file = fullfile(output_dir, [num2str(equation_index), '.tex']);
fid = fopen(equation_file, 'w');
fwrite(fid, equation_content);
fclose(fid);
end

function equation_basename = compile_equation(equation_file)
[~, equation_basename, ~] = fileparts(equation_file);
output_dir = fileparts(equation_file);
pdf_file = fullfile(output_dir, [equation_basename, '.pdf']);

% Convert to absolute paths
equation_file = fullfile(pwd, equation_file);
output_dir = fullfile(pwd, output_dir);
pdf_file = fullfile(pwd, pdf_file);

% Check if the PDF file already exists
if exist(pdf_file, 'file')
    fprintf('Skipping compilation for equation %s.pdf. PDF file already exists.\n', equation_basename);
    return;
end

run_pdflatex(equation_file, output_dir);
end
function run_pdflatex(equation_file, output_dir)

% Specify the pdflatex command with custom options
cmd = ['pdflatex -output-directory ','"', fileparts(equation_file), '" "',equation_file,'"'];

[status, result] = system(cmd);

if status ~= 0
    fprintf('Failed to run pdflatex. Error: %s\n', result);
    return;
end

[~, equation_basename, ~] = fileparts(equation_file);
fprintf('Equation %s compiled successfully.\n', equation_basename);
end


function convert_pdf_to_svg(pdf_file, svg_file, inkscape_path)

try
    cmd = ['"', inkscape_path, '"', ' --pdf-poppler --export-type=svg --export-filename="', svg_file, '" "', pdf_file, '"'];

    [~, ~] = system(cmd, '-echo');
    fprintf('Successfully converted %s to SVG.\n', pdf_file);
catch e
    fprintf('Failed to convert %s to SVG. Error: %s\n', pdf_file, e.message);
end
end
