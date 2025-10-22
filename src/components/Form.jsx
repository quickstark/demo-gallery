import React, { useState } from 'react';
import {
  Box,
  Button,
  Field,
  Input,
  Textarea,
  VStack,
  Container
} from '@chakra-ui/react';
import apiClient from '../utils/apiClient';
import { useAppToaster } from '../hooks/useAppToaster';

function Form() {
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    body: '',
    userId: ''
  });
  const toaster = useAppToaster();

  const createPost = async (data) => {
    const res = await apiClient({
      method: "post",
      url: `/create_post`,
      data: data,
      headers: { 
        "Content-Type": "application/json"
      }
    });
    return res;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      const res = await createPost(formData);
      
      if (res.status === 200 || res.status === 201) {
        toaster.create({
          title: 'Post Created',
          description: `Successfully created post with title: ${formData.title}`,
          status: 'success',
          duration: 5000,
        });
        
        // Reset form
        setFormData({ title: '', body: '', userId: '' });
      }
      
    } catch (error) {
      console.error('Error creating post:', error);
      toaster.create({
        title: 'Error',
        description: error.response?.data?.message || 'Failed to create post',
        status: 'error',
        duration: 5000,
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <Container maxW="container.md" py={8}>
      <Box as="form" onSubmit={handleSubmit}>
        <VStack spacing={4}>
          <Field.Root required>
            <Field.Label>Title</Field.Label>
            <Input
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Enter post title"
            />
          </Field.Root>

          <Field.Root required>
            <Field.Label>Body</Field.Label>
            <Textarea
              name="body"
              value={formData.body}
              onChange={handleChange}
              placeholder="Enter post content"
              rows={6}
            />
          </Field.Root>

          <Field.Root required>
            <Field.Label>User ID</Field.Label>
            <Input
              name="userId"
              value={formData.userId}
              onChange={handleChange}
              placeholder="Enter user ID"
              type="number"
            />
          </Field.Root>

          <Button
            type="submit"
            colorScheme="blue"
            width="full"
            isLoading={isLoading}
            loadingText="Creating Post"
          >
            Create Post
          </Button>
        </VStack>
      </Box>
    </Container>
  );
}

export default Form; 