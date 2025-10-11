#include <stdio.h>
#include <string>
#include <fstream>
#include <vector>
#include <format>

std::string getFileBaseName( const std::string& _path )
{
	std::string base_filename = _path.substr( _path.find_last_of( "/\\" ) + 1 );
	std::string::size_type const p( base_filename.find_last_of( '.' ) );
	return base_filename.substr( 0, p );
}

std::string getFileExtension( const std::string& _path )
{
	return _path.substr( _path.find_last_of( "." ) + 1 );
}

std::string convertData( const std::string& _name, unsigned char* _data, size_t _data_size, int _row_length, bool _compact )
{
	std::string out_lua_str = "";
	out_lua_str += "local " + _name + " = { \n";
	if ( !_compact )
		out_lua_str += "  ";

	for ( size_t i = 0; i < _data_size; i++ )
	{
		out_lua_str += std::format( 
			"{:#04x}{}{}", 
			_data[ i ], 
			( i < _data_size - 1 ) ? "," : "",
			_compact ? "" : " "
		);
		
		if ( ( i + 1 ) % _row_length == 0 || i == _data_size - 1 )
		{
			out_lua_str += "\n";
			if ( !_compact && i < _data_size - 1 )
				out_lua_str += "  ";
		}		
	}

	out_lua_str += "}";
	return out_lua_str;
}

void createDebugFile()
{
	char debug_data[] = {
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
		0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00,
		0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	};

	std::ofstream file( "DEBUG.bin", std::ios::binary );
	file.write( debug_data, sizeof( debug_data ) );
	file.close();
}

int main(int _argc, char* _argv[])
{
	std::string out_path  = "";
	std::vector<std::string> paths         = {};
	std::vector<std::string> generated_lua = {};
	std::vector<std::string> local_names   = {};
	
	int row_length = 8;
	bool compact   = false;
	bool define_fs = false;

	if ( _argc >= 2 )
	{
		std::string arg1 = _argv[ 1 ];
		if ( arg1 == "help" || arg1 == "--help" )
		{
			printf( "Usage: bin_converter [options] file...\n" );
			printf( "Command line options:\n" );
			printf( "  -o <file>      Output into <file>.\n" );
			printf( "  -r <length>    Set the number of bytes before a newline (default 8).\n" );
			printf( "  -c             Compact formatting.\n" );
			printf( "  -fs            Define virtual filesystem.\n" );
			return 0;
		}

		int arg_index = 1;
		while ( arg_index < _argc )
		{
			std::string arg = _argv[ arg_index ];

			if ( arg[ 0 ] == '-' ) // command options
			{
				if ( arg == "-o" )
				{
					out_path = _argv[ arg_index + 1 ];
					arg_index++;
				}
				else if ( arg == "-r" )
				{
					row_length = std::stoi( _argv[ arg_index + 1 ] );
					arg_index++;
				}
				else if ( arg == "-c" )
				{
					compact = true;
				}
				else if ( arg == "-fs" )
				{
					define_fs = true;
				}
				else
				{
					printf( "unknown command line option '%s'\n", arg.c_str() );
					return 1;
				}
			}
			else
			{
				paths.push_back( arg );
			}

			arg_index++;
		}

	}
	else
	{
		createDebugFile();
		paths.push_back( "DEBUG.bin" );
		out_path  = "DEBUG.lua";
	}
	
	if ( paths.empty() )
		return 1;

	// convert files
	for ( size_t i = 0; i < paths.size(); i++ )
	{
		// open file
		std::ifstream load_file( paths[ i ], std::ios::binary );
		if ( load_file.is_open() )
		{
			std::vector<unsigned char> buffer( std::istreambuf_iterator<char>( load_file ), {} );
			local_names.push_back( getFileBaseName( paths[ i ] ) + "_" + getFileExtension( paths[ i ] ) );

			// convert and push
			generated_lua.push_back( 
				convertData( 
					local_names[ i ],
					buffer.data(), 
					buffer.size(), 
					row_length, 
					compact 
				) );
		}
		else
		{
			// dummy symbol
			local_names.push_back( "nil" );
		}
	}

	if ( define_fs )
	{
		std::string out_lua_src;
		out_lua_src += "local virtual_filesystem = {\n";
		for ( size_t i = 0; i < paths.size(); i++ )
			out_lua_src += std::format( "  [\"{}\"] = {}{}\n", paths[ i ], local_names[ i ], i == paths.size() - 1 ? "" : "," );
		out_lua_src += "}";

		generated_lua.push_back( out_lua_src );
	}

	if ( out_path == "" )
		out_path = local_names[ 0 ] + ".lua";

	std::ofstream out_stream( out_path );
	if ( out_stream.is_open() )
	{
		for ( size_t i = 0; i < generated_lua.size(); i++ )
			out_stream << generated_lua[ i ] + "\n";
		
		out_stream.close();
	}

	return 0;
}
