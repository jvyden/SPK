struct package_metadata {
  u8 name_length;
  char name[name_length];
  u8 description_length;
  char description[description_length];
  u8 semver_major;
  u8 semver_minor;
  u8 semver_patch;
};

struct file {
  u16 path_length;
  char path[path_length];
  u32 data_offset;
  u32 data_length;
};

struct package {
  be u32 magic;
  u8 format_version;
  package_metadata metadata;
  u16 file_count;
  file file_table[file_count];
};

package package @ 0x00;