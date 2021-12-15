<?php declare(strict_types=1);

namespace App\Service;

use App\Repository\DataRepositoryInterface;

final class DataService
{
    public function __construct(private DataRepositoryInterface $repository) {}

    public function createData(array $data): bool
    {
        return $this->repository->insert($data);
    }

    public function getData(): array
    {
        return $this->repository->findAll();
    }
}
